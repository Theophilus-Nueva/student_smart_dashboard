import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_item.dart';

/// Recent Activity feed (Week 1 placeholder, fed by later weeks' events).
class ActivityLog extends ChangeNotifier {
  ActivityLog(this._prefs);

  static const _key = 'activity.items';
  static const _seenKey = 'activity.lastSeen';
  static const maxItems = 50;

  final SharedPreferences _prefs;
  List<ActivityItem> _items = [];
  DateTime? _lastSeen;

  List<ActivityItem> get items => List.unmodifiable(_items);

  int get unreadCount => _lastSeen == null
      ? _items.length
      : _items.where((i) => i.time.isAfter(_lastSeen!)).length;

  void load() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _items = (jsonDecode(raw) as List<dynamic>)
            .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException {
        _items = [];
      }
    }
    final seen = _prefs.getString(_seenKey);
    _lastSeen = seen == null ? null : DateTime.tryParse(seen);
  }

  Future<void> add(
    ActivityKind kind,
    String title, [
    String description = '',
  ]) async {
    _items.insert(
      0,
      ActivityItem(
        kind: kind,
        title: title,
        description: description,
        time: DateTime.now(),
      ),
    );
    if (_items.length > maxItems) _items = _items.sublist(0, maxItems);
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    _lastSeen = DateTime.now();
    notifyListeners();
    await _prefs.setString(_seenKey, _lastSeen!.toIso8601String());
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    await _prefs.remove(_key);
  }
}
