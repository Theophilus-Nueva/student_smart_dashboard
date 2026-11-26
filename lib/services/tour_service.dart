import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tour.dart';
import 'syncable.dart';

/// Week 7 tour module: visits and added locations (offline queue),
/// bookmarks and progress.
class TourService extends ChangeNotifier implements Syncable {
  TourService(this._prefs, {Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  static const _visitsKey = 'tour.visits';
  static const _bookmarksKey = 'tour.bookmarks';
  static const _addedKey = 'tour.addedLocations';

  final SharedPreferences _prefs;
  final Future<Directory> Function() _documentsDirectory;
  List<Visit> _visits = [];
  Set<String> _bookmarks = {};

  /// Locations added in the app, oldest first.
  List<TourLocation> _added = [];

  /// The six built-in locations, then the ones added in the app.
  List<TourLocation> get locations => [...campusLocations, ..._added];

  /// Locations added through the Add Location form, newest first.
  List<TourLocation> get addedLocations => _added.reversed.toList();

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
    final added = _prefs.getString(_addedKey);
    if (added != null) {
      _added = (jsonDecode(added) as List<dynamic>)
          .map((e) => TourLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  TourLocation? byId(String id) {
    for (final l in locations) {
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

  /// Location whose checkpoint QR code is [code] (e.g. "UC002"), if any.
  TourLocation? byQrCode(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    for (final l in campusLocations) {
      if (l.qrCode == c) return l;
    }
    return null;
  }

  // ---- Week 7 AR guided route ---------------------------------------------

  List<TourLocation> get routeStops => [for (final id in arRouteIds) byId(id)!];

  int get routeVisitedCount => routeStops.where((l) => isVisited(l.id)).length;

  double get routeProgress =>
      routeStops.isEmpty ? 0 : routeVisitedCount / routeStops.length;

  /// The route stop visited most recently, or null before the first scan.
  TourLocation? get currentRouteStop {
    for (final v in visits) {
      if (arRouteIds.contains(v.locationId)) return byId(v.locationId);
    }
    return null;
  }

  /// First route stop not visited yet, or null when the route is done.
  TourLocation? get nextRouteStop {
    for (final l in routeStops) {
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

  /// Week 7 offline queue: saves a new location on the phone with
  /// `synced = false`; it uploads with the next sync. [photo] (taken or
  /// picked) is copied into the app's own folder so it stays available.
  Future<TourLocation> addLocation({
    required String title,
    required String description,
    String subtitle = '',
    String hours = '',
    File? photo,
  }) async {
    final now = DateTime.now();
    final id = 'added-${now.microsecondsSinceEpoch}';
    String? photoFile;
    if (photo != null) {
      final dir = Directory('${(await _documentsDirectory()).path}/tour');
      await dir.create(recursive: true);
      final ext = photo.path.contains('.')
          ? photo.path.substring(photo.path.lastIndexOf('.'))
          : '.jpg';
      photoFile = (await photo.copy('${dir.path}/$id$ext')).path;
    }
    final location = TourLocation(
      id: id,
      title: title.trim(),
      subtitle: subtitle.trim().isEmpty ? 'Added location' : subtitle.trim(),
      description: description.trim(),
      hours: hours.trim(),
      distanceMeters: 0,
      qrCode: '',
      photoFile: photoFile,
      addedByUser: true,
      synced: false,
      createdAt: now,
    );
    _added.add(location);
    await _saveAdded();
    return location;
  }

  /// Removes an added location, its photo, bookmark and visits.
  Future<void> deleteLocation(String id) async {
    final i = _added.indexWhere((l) => l.id == id);
    if (i < 0) return;
    final photo = _added.removeAt(i).photoFile;
    if (photo != null) {
      try {
        await File(photo).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    _visits.removeWhere((v) => v.locationId == id);
    if (_bookmarks.remove(id)) {
      await _prefs.setStringList(_bookmarksKey, _bookmarks.toList());
    }
    await _saveVisits();
    await _saveAdded();
  }

  Future<void> _saveAdded() async {
    notifyListeners();
    await _prefs.setString(
      _addedKey,
      jsonEncode(_added.map((l) => l.toJson()).toList()),
    );
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

  /// Visits not uploaded yet (AR guide "Pending Visit Uploads").
  int get pendingVisitCount => _visits.where((v) => !v.synced).length;

  /// Added locations not uploaded yet.
  int get pendingLocationCount => _added.where((l) => !l.synced).length;

  @override
  int get pendingCount => pendingVisitCount + pendingLocationCount;

  @override
  int get totalCount => _visits.length + _added.length;

  @override
  Future<void> markAllSynced() async {
    if (pendingCount == 0) return;
    if (pendingVisitCount > 0) {
      _visits = [for (final v in _visits) v.copyWith(synced: true)];
      await _saveVisits();
    }
    if (pendingLocationCount > 0) {
      _added = [for (final l in _added) l.copyWith(synced: true)];
      await _saveAdded();
    }
  }
}
