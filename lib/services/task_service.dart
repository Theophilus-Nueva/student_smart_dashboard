import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'syncable.dart';

/// A Cloud Tasks item (Week 6: `task` + `timestamp`).
class CloudTask {
  const CloudTask({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.done = false,
    this.synced = false,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final bool done;
  final bool synced;

  CloudTask copyWith({String? title, bool? done, bool? synced, DateTime? at}) =>
      CloudTask(
        id: id,
        title: title ?? this.title,
        updatedAt: at ?? updatedAt,
        done: done ?? this.done,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'task': title,
    'timestamp': updatedAt.toIso8601String(),
    'done': done,
    'synced': synced,
  };

  factory CloudTask.fromJson(Map<String, dynamic> json) => CloudTask(
    id: json['id'] as String,
    title: json['task'] as String,
    updatedAt: DateTime.parse(json['timestamp'] as String),
    done: json['done'] as bool? ?? false,
    synced: json['synced'] as bool? ?? false,
  );
}

/// Cloud copy of the tasks (Firestore in the app, a fake in tests).
abstract class TaskRemote {
  Stream<List<CloudTask>> watch();
  Future<void> upsert(CloudTask task);
  Future<void> delete(String id);
}

/// Tasks live on the phone first (Week 7 offline queue) and are pushed to
/// the cloud when the sync service runs. With a [TaskRemote] attached, live
/// cloud changes stream back in (Week 6 StreamBuilder behaviour).
class TaskService extends ChangeNotifier implements Syncable {
  TaskService(this._prefs);

  static const _key = 'tasks';

  final SharedPreferences _prefs;
  List<CloudTask> _tasks = [];
  TaskRemote? _remote;
  StreamSubscription<List<CloudTask>>? _remoteSub;

  bool get isCloudConnected => _remote != null;

  void attachRemote(TaskRemote remote) {
    _remote = remote;
    _remoteSub?.cancel();
    _remoteSub = remote.watch().listen(_mergeRemote, onError: (Object _) {});
  }

  /// Cloud list wins for synced tasks; local unsynced edits are kept.
  void _mergeRemote(List<CloudTask> remote) {
    final pending = _tasks.where((t) => !t.synced).toList();
    final pendingIds = pending.map((t) => t.id).toSet();
    _tasks = [...pending, ...remote.where((t) => !pendingIds.contains(t.id))];
    unawaited(_save());
  }

  /// Open tasks first, newest first.
  List<CloudTask> get tasks => List.unmodifiable(
    [..._tasks]..sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return b.updatedAt.compareTo(a.updatedAt);
    }),
  );

  int get completedCount => _tasks.where((t) => t.done).length;

  void load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      _tasks = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CloudTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      _tasks = [];
    }
  }

  Future<void> add(String title) async {
    final now = DateTime.now();
    _tasks.add(
      CloudTask(
        id: now.microsecondsSinceEpoch.toString(),
        title: title.trim(),
        updatedAt: now,
      ),
    );
    await _save();
  }

  Future<void> rename(String id, String title) =>
      _change(id, (t) => t.copyWith(title: title.trim()));

  Future<void> toggleDone(String id) =>
      _change(id, (t) => t.copyWith(done: !t.done));

  Future<void> delete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _save();
    // Firestore queues the delete itself while offline.
    unawaited(_remote?.delete(id).catchError((Object _) {}));
  }

  Future<void> _change(String id, CloudTask Function(CloudTask) edit) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i] = edit(_tasks[i]).copyWith(synced: false, at: DateTime.now());
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
  }

  @override
  int get pendingCount => _tasks.where((t) => !t.synced).length;

  @override
  int get totalCount => _tasks.length;

  @override
  Future<void> markAllSynced() async {
    if (pendingCount == 0) return;
    final remote = _remote;
    if (remote != null) {
      for (final t in _tasks.where((t) => !t.synced).toList()) {
        try {
          await remote.upsert(t).timeout(const Duration(seconds: 10));
        } on Object {
          break; // Leave the rest pending; the next sync retries.
        }
        final i = _tasks.indexWhere((x) => x.id == t.id);
        if (i != -1) _tasks[i] = _tasks[i].copyWith(synced: true);
      }
    } else {
      _tasks = [for (final t in _tasks) t.copyWith(synced: true)];
    }
    await _save();
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }
}
