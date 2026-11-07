import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tour.dart';
import 'syncable.dart';

/// Week 7 tour module: visits (offline queue), bookmarks and progress.
class TourService extends ChangeNotifier implements Syncable {
  TourService(this._prefs);

  static const _visitsKey = 'tour.visits';
  static const _bookmarksKey = 'tour.bookmarks';

  final SharedPreferences _prefs;
  List<Visit> _visits = [];
  Set<String> _bookmarks = {};

  List<TourLocation> get locations => campusLocations;

  /// Newest first.
  List<Visit> get visits =>
      List.unmodifiable([..._visits]..sort((a, b) => b.time.compareTo(a.time)));

  void load() {
    final raw = _prefs.getString(_visitsKey);
    if (raw != null) {
      try {
        _visits = (jsonDecode(raw) as List<dynamic>)
            .map((e) => Visit.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException {
        _visits = [];
      }
    }
    _bookmarks = (_prefs.getStringList(_bookmarksKey) ?? []).toSet();
  }

  TourLocation? byId(String id) {
    for (final l in campusLocations) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Visit> visitsFor(String locationId) =>
      visits.where((v) => v.locationId == locationId).toList();

  bool isVisited(String locationId) =>
      _visits.any((v) => v.locationId == locationId);

  bool isBookmarked(String locationId) => _bookmarks.contains(locationId);

  int get visitedCount => campusLocations.where((l) => isVisited(l.id)).length;

  double get progress =>
      campusLocations.isEmpty ? 0 : visitedCount / campusLocations.length;

  /// First unvisited stop on the guided route, or null when finished.
  TourLocation? get nextStop {
    for (final l in campusLocations) {
      if (!isVisited(l.id)) return l;
    }
    return null;
  }

  Future<void> recordVisit(String locationId) async {
    _visits.add(Visit(locationId: locationId, time: DateTime.now()));
    await _saveVisits();
  }

  Future<void> toggleBookmark(String locationId) async {
    if (!_bookmarks.remove(locationId)) _bookmarks.add(locationId);
    notifyListeners();
    await _prefs.setStringList(_bookmarksKey, _bookmarks.toList());
  }

  Future<void> resetVisits() async {
    _visits = [];
    await _saveVisits();
  }

  Future<void> _saveVisits() async {
    notifyListeners();
    await _prefs.setString(
      _visitsKey,
      jsonEncode(_visits.map((v) => v.toJson()).toList()),
    );
  }

  @override
  int get pendingCount => _visits.where((v) => !v.synced).length;

  @override
  int get totalCount => _visits.length;

  @override
  Future<void> markAllSynced() async {
    if (pendingCount == 0) return;
    _visits = [for (final v in _visits) v.copyWith(synced: true)];
    await _saveVisits();
  }
}
