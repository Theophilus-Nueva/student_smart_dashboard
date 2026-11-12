import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// A position reading for the Current Location card (Week 6).
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.altitudeMeters,
    required this.address,
    required this.live,
    this.problem,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedKmh;
  final double altitudeMeters;
  final String address;

  /// True for a GPS reading; false for the built-in campus sample.
  final bool live;

  /// Why GPS isn't live (service off, permission denied…), if known.
  final String? problem;

  LocationFix withAddress(String value) => LocationFix(
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracyMeters,
    speedKmh: speedKmh,
    altitudeMeters: altitudeMeters,
    address: value,
    live: live,
    problem: problem,
  );

  /// Short place name for the Home card: the campus name when on campus,
  /// otherwise the looked-up place name (or coordinates when offline).
  String get placeName => address == LocationService.campusAddress
      ? LocationService.campusName
      : address;
}

/// A labelled map point (Week 6: Home, School and Workplace markers).
class MapMarker {
  const MapMarker(this.label, this.latitude, this.longitude);

  final String label;
  final double latitude;
  final double longitude;
}

abstract class LocationService {
  /// LPU Cavite campus, from the Figma design.
  static const campus = LocationFix(
    latitude: 14.3290,
    longitude: 120.9370,
    accuracyMeters: 5,
    speedKmh: 0,
    altitudeMeters: 18,
    address: campusAddress,
    live: false,
  );

  static const campusName = 'Lyceum of the Philippines University Cavite';

  static const campusAddress =
      'Lyceum of the Philippines University Cavite, Governor’s Drive, '
      'Manggahan, General Trias, Cavite';

  /// Sample markers (invented coordinates near campus, as in the prototype).
  static const markers = [
    MapMarker('School', 14.3290, 120.9370),
    MapMarker('Home', 14.3412, 120.9268),
    MapMarker('Workplace', 14.3175, 120.9502),
  ];

  Future<LocationFix> current();
  Stream<LocationFix> watch();
}

/// Always returns the campus sample (tests, and devices without GPS).
class SampleLocationService implements LocationService {
  const SampleLocationService();

  @override
  Future<LocationFix> current() async => LocationService.campus;

  @override
  Stream<LocationFix> watch() => Stream.value(LocationService.campus);
}

/// GPS through `geolocator`, with the service and permission checks from
/// the Week 6 LocationService.
class GpsLocationService implements LocationService {
  const GpsLocationService();

  /// Returns null when GPS can be used, otherwise the reason it can't.
  Future<String?> _ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location services are off';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => 'Location permission denied',
      LocationPermission.deniedForever =>
        'Location permission blocked in Settings',
      _ => null,
    };
  }

  /// Last place-name lookup; reused until the phone moves 150 m, so the
  /// phone's geocoder (which limits how often it can be asked) isn't
  /// called on every GPS update.
  static ({double lat, double lng, String name})? _lastPlace;

  /// Replaces the coordinates with the place name from the phone's map
  /// service (Apple or Google). Keeps the coordinates if that fails, e.g.
  /// offline.
  static Future<LocationFix> _withPlaceName(LocationFix fix) async {
    if (fix.address == LocationService.campusAddress) return fix;
    final last = _lastPlace;
    if (last != null &&
        _distanceMeters(last.lat, last.lng, fix.latitude, fix.longitude) <
            150) {
      return fix.withAddress(last.name);
    }
    try {
      final marks = await geo.Geocoding().placemarkFromCoordinates(
        fix.latitude,
        fix.longitude,
      );
      final name = marks.isEmpty ? null : placeLabel(marks.first);
      if (name == null) return fix;
      _lastPlace = (lat: fix.latitude, lng: fix.longitude, name: name);
      return fix.withAddress(name);
    } on Object {
      return fix;
    }
  }

  /// e.g. "SM City Rosario, Rosario, Cavite": place, town, province.
  @visibleForTesting
  static String? placeLabel(geo.Placemark m) {
    final parts = <String>[];
    bool usable(String? v) =>
        v != null && v.trim().isNotEmpty && !RegExp(r'^[0-9 -]+$').hasMatch(v);
    for (final part in [
      // The street stands in when the place has no name of its own.
      usable(m.name) ? m.name : m.thoroughfare,
      m.locality ?? m.subAdministrativeArea,
      m.administrativeArea,
    ]) {
      final p = part?.trim() ?? '';
      if (!usable(p) || parts.contains(p)) continue;
      parts.add(p);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static LocationFix _fromPosition(Position p) {
    final nearCampus =
        _distanceMeters(
          p.latitude,
          p.longitude,
          LocationService.campus.latitude,
          LocationService.campus.longitude,
        ) <
        600;
    return LocationFix(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      speedKmh: p.speed < 0 ? 0 : p.speed * 3.6,
      altitudeMeters: p.altitude,
      address: nearCampus
          ? LocationService.campusAddress
          : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
      live: true,
    );
  }

  static LocationFix _fallback(String problem) => LocationFix(
    latitude: LocationService.campus.latitude,
    longitude: LocationService.campus.longitude,
    accuracyMeters: LocationService.campus.accuracyMeters,
    speedKmh: 0,
    altitudeMeters: LocationService.campus.altitudeMeters,
    address: LocationService.campusAddress,
    live: false,
    problem: problem,
  );

  @override
  Future<LocationFix> current() async {
    final problem = await _ensureAccess();
    if (problem != null) return _fallback(problem);
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return await _withPlaceName(_fromPosition(p));
    } on Exception {
      return _fallback('Could not get a GPS fix');
    }
  }

  @override
  Stream<LocationFix> watch() async* {
    final problem = await _ensureAccess();
    if (problem != null) {
      yield _fallback(problem);
      return;
    }
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map(_fromPosition).asyncMap(_withPlaceName).handleError((Object _) {});
  }
}

/// Holds the latest fix for the UI and keeps it updated while signed in.
class LocationTracker extends ChangeNotifier {
  LocationTracker(this._service);

  final LocationService _service;
  StreamSubscription<LocationFix>? _sub;
  LocationFix _fix = LocationService.campus;

  LocationFix get fix => _fix;
  bool get running => _sub != null;

  void start() {
    if (_sub != null) return;
    _sub = _service.watch().listen((fix) {
      _fix = fix;
      notifyListeners();
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}
