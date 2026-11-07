import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/network_status.dart';
import 'syncable.dart';

/// Returns true when the internet is reachable.
typedef ConnectionCheck = Future<bool> Function();

/// Default check until `connectivity_plus` is added: can we reach the
/// Week 2 API host at all?
Future<bool> pingApiHost() async {
  try {
    await http
        .head(Uri.parse('https://jsonplaceholder.typicode.com/users/1'))
        .timeout(const Duration(seconds: 5));
    return true;
  } on Exception {
    return false;
  }
}

class ConnectivityLog {
  const ConnectivityLog({required this.online, required this.time});

  final bool online;
  final DateTime time;

  String get status => online ? 'ONLINE' : 'OFFLINE';

  Map<String, dynamic> toJson() => {
    'online': online,
    'time': time.toIso8601String(),
  };

  factory ConnectivityLog.fromJson(Map<String, dynamic> json) =>
      ConnectivityLog(
        online: json['online'] as bool,
        time: DateTime.parse(json['time'] as String),
      );
}

/// Week 7 offline queue: tracks connectivity, counts pending records across
/// every [Syncable] store, and syncs them (automatically or via Sync Now).
class SyncService extends ChangeNotifier {
  SyncService(this._prefs, this._stores, {ConnectionCheck? check})
    : _check = check ?? pingApiHost {
    for (final store in _stores) {
      store.addListener(_onStoreChanged);
    }
  }

  static const _autoKey = 'sync.auto';
  static const _lastKey = 'sync.last';
  static const _countKey = 'sync.completed';
  static const _logKey = 'sync.log';

  final SharedPreferences _prefs;
  final List<Syncable> _stores;
  final ConnectionCheck _check;

  bool _online = true;
  bool _syncing = false;
  bool _autoSync = true;
  DateTime? _lastSync;
  int _completedSyncs = 0;
  List<ConnectivityLog> _log = [];

  /// Called after each successful sync (used by the activity log).
  void Function(int synced)? onSynced;

  /// Called when connectivity changes (used by the activity log).
  void Function(bool online)? onConnectivityChanged;

  bool get online => _online;
  bool get syncing => _syncing;
  bool get autoSync => _autoSync;
  DateTime? get lastSync => _lastSync;
  int get completedSyncs => _completedSyncs;
  List<ConnectivityLog> get log => List.unmodifiable(_log);

  int get pendingCount => _stores.fold(0, (sum, s) => sum + s.pendingCount);
  int get totalCount => _stores.fold(0, (sum, s) => sum + s.totalCount);

  NetworkState get state {
    if (!_online) return NetworkState.offline;
    if (pendingCount > 0) return NetworkState.pending;
    return NetworkState.online;
  }

  void load() {
    _autoSync = _prefs.getBool(_autoKey) ?? true;
    final last = _prefs.getString(_lastKey);
    _lastSync = last == null ? null : DateTime.tryParse(last);
    _completedSyncs = _prefs.getInt(_countKey) ?? 0;
    final raw = _prefs.getString(_logKey);
    if (raw != null) {
      try {
        _log = (jsonDecode(raw) as List<dynamic>)
            .map((e) => ConnectivityLog.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException {
        _log = [];
      }
    }
  }

  Future<bool> checkConnection() async {
    final online = await _check();
    await setOnline(online);
    return online;
  }

  Future<void> setOnline(bool online) async {
    final changed = online != _online || _log.isEmpty;
    _online = online;
    if (changed) {
      _log.insert(0, ConnectivityLog(online: online, time: DateTime.now()));
      if (_log.length > 20) _log = _log.sublist(0, 20);
      await _prefs.setString(
        _logKey,
        jsonEncode(_log.map((e) => e.toJson()).toList()),
      );
      onConnectivityChanged?.call(online);
    }
    notifyListeners();
    if (online) _maybeAutoSync();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool(_autoKey, value);
    notifyListeners();
    _maybeAutoSync();
  }

  /// SYNC NOW. Returns false when offline.
  Future<bool> syncNow() async {
    if (_syncing) return false;
    if (!_online) return false;
    _syncing = true;
    notifyListeners();
    final count = pendingCount;
    try {
      for (final store in _stores) {
        await store.markAllSynced();
      }
      _lastSync = DateTime.now();
      _completedSyncs++;
      await _prefs.setString(_lastKey, _lastSync!.toIso8601String());
      await _prefs.setInt(_countKey, _completedSyncs);
      onSynced?.call(count);
      return true;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void _onStoreChanged() {
    notifyListeners();
    _maybeAutoSync();
  }

  void _maybeAutoSync() {
    if (_autoSync && _online && !_syncing && pendingCount > 0) {
      unawaited(syncNow());
    }
  }

  @override
  void dispose() {
    for (final store in _stores) {
      store.removeListener(_onStoreChanged);
    }
    super.dispose();
  }
}
