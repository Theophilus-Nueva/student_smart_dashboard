import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';
import 'syncable.dart';

/// Student list saved as one JSON string under "students" (Week 4).
class StudentRepository extends ChangeNotifier implements Syncable {
  StudentRepository(this._prefs);

  static const storageKey = 'students';

  final SharedPreferences _prefs;
  List<Student> _students = [];

  List<Student> get all => List.unmodifiable(
    [..._students]..sort((a, b) => a.name.compareTo(b.name)),
  );

  void load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) {
      _students = [...sampleStudents];
      return;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _students = list
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    await _prefs.setString(
      storageKey,
      jsonEncode(_students.map((s) => s.toJson()).toList()),
    );
    notifyListeners();
  }

  Student? byId(String id) {
    for (final s in _students) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool idExists(String id) => byId(id) != null;

  Future<void> add(Student student) async {
    _students.add(student.copyWith(synced: false));
    await _save();
  }

  /// [originalId] lets the form change a student's ID.
  Future<void> update(String originalId, Student student) async {
    final i = _students.indexWhere((s) => s.id == originalId);
    if (i == -1) return;
    _students[i] = student.copyWith(synced: false);
    await _save();
  }

  Future<void> delete(String id) async {
    _students.removeWhere((s) => s.id == id);
    await _save();
  }

  /// Settings › Reset Database: back to the sample records.
  Future<void> reset() async {
    _students = [...sampleStudents];
    await _save();
  }

  List<Student> search(String query, {String? program}) {
    final q = query.trim().toLowerCase();
    return all.where((s) {
      final matchesProgram = program == null || s.program == program;
      final matchesQuery =
          q.isEmpty ||
          s.id.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q);
      return matchesProgram && matchesQuery;
    }).toList();
  }

  // Week 4 dashboard stats.
  int get total => _students.length;

  double get averageGrade => _students.isEmpty
      ? 0
      : _students.map((s) => s.grade).reduce((a, b) => a + b) /
            _students.length;

  Student? get topPerformer => _students.isEmpty
      ? null
      : _students.reduce((a, b) => a.grade >= b.grade ? a : b);

  Map<String, int> get countByProgram => {
    for (final p in Student.programs)
      p: _students.where((s) => s.program == p).length,
  };

  @override
  int get pendingCount => _students.where((s) => !s.synced).length;

  @override
  int get totalCount => _students.length;

  @override
  Future<void> markAllSynced() async {
    if (pendingCount == 0) return;
    _students = [for (final s in _students) s.copyWith(synced: true)];
    await _save();
  }
}
