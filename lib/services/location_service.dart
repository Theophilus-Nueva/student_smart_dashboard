/// Current position (Week 6). Until `geolocator` is added this returns the
/// LPU Cavite campus coordinates from the Figma design, marked as not live.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.altitudeMeters,
    required this.address,
    required this.live,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedKmh;
  final double altitudeMeters;
  final String address;

  /// False while the position is the built-in campus sample.
  final bool live;
}

/// A labelled map point (Week 6: Home, School and Workplace markers).
class MapMarker {
  const MapMarker(this.label, this.latitude, this.longitude);

  final String label;
  final double latitude;
  final double longitude;
}

class LocationService {
  const LocationService();

  static const campus = LocationFix(
    latitude: 14.3290,
    longitude: 120.9370,
    accuracyMeters: 5,
    speedKmh: 0,
    altitudeMeters: 18,
    address:
        'Lyceum of the Philippines University Cavite, Governor’s Drive, '
        'Manggahan, General Trias, Cavite',
    live: false,
  );

  /// Sample markers (invented coordinates near campus, as in the prototype).
  static const markers = [
    MapMarker('School', 14.3290, 120.9370),
    MapMarker('Home', 14.3412, 120.9268),
    MapMarker('Workplace', 14.3175, 120.9502),
  ];

  Future<LocationFix> current() async => campus;
}
