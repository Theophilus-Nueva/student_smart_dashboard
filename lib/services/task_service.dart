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

/// Local task store. Firestore (`dashboard` collection) replaces the
/// storage once `firebase_core` / `cloud_firestore` are added; until then
/// tasks persist on the phone and join the Week 7 sync queue.
class TaskService extends ChangeNotifier implements Syncable {
  TaskService(this._prefs);

  static const _key = 'tasks';

  final SharedPreferences _prefs;
  List<CloudTask> _tasks = [];

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
    _tasks = [for (final t in _tasks) t.copyWith(synced: true)];
    await _save();
  }
}
