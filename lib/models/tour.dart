/// Campus location for the Week 7 tour. Merges the lab's two `TourLocation`
/// definitions (title/description/synced and qrCode/imagePath/visited);
/// visit state lives in [Visit] so the location list itself stays static.
class TourLocation {
  const TourLocation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.hours,
    required this.distanceMeters,
    required this.qrCode,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String hours;

  /// Estimated distance from the campus entrance until GPS is added.
  final int distanceMeters;

  /// Week 7 checkpoint code (kept for the model; the AR guide is out of scope).
  final String qrCode;

  /// About 80 m per minute of walking.
  int get walkMinutes => (distanceMeters / 80).ceil().clamp(1, 60);
}

/// A recorded visit (Week 7 VisitHistory). Created offline with
/// `synced = false` and uploaded by the sync service.
class Visit {
  const Visit({
    required this.locationId,
    required this.time,
    this.synced = false,
  });

  final String locationId;
  final DateTime time;
  final bool synced;

  Visit copyWith({bool? synced}) =>
      Visit(locationId: locationId, time: time, synced: synced ?? this.synced);

  Map<String, dynamic> toJson() => {
    'locationId': locationId,
    'time': time.toIso8601String(),
    'synced': synced,
  };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    locationId: json['locationId'] as String,
    time: DateTime.parse(json['time'] as String),
    synced: json['synced'] as bool? ?? false,
  );
}

/// The six Week 7 locations, in guided-route order.
const campusLocations = <TourLocation>[
  TourLocation(
    id: 'main-building',
    title: 'Main Building',
    subtitle: 'Administration and classrooms',
    description:
        'The main academic building with administrative offices and '
        'general classrooms.',
    hours: 'Open 7:00 AM – 9:00 PM',
    distanceMeters: 20,
    qrCode: 'UC001',
  ),
  TourLocation(
    id: 'library',
    title: 'Library',
    subtitle: 'Learning and Research Center',
    description:
        'Books, journals, study areas and computer terminals for '
        'research.',
    hours: 'Open 7:00 AM – 8:00 PM',
    distanceMeters: 50,
    qrCode: 'UC002',
  ),
  TourLocation(
    id: 'computer-lab',
    title: 'Computer Laboratory',
    subtitle: 'COECSA laboratories',
    description:
        'Computer laboratories used by the College of Computer Studies.',
    hours: 'Open 7:00 AM – 7:00 PM',
    distanceMeters: 120,
    qrCode: 'UC004',
  ),
  TourLocation(
    id: 'student-center',
    title: 'Student Center',
    subtitle: 'Student services and organisations',
    description: 'Student affairs, organisation offices and lounge areas.',
    hours: 'Open 8:00 AM – 6:00 PM',
    distanceMeters: 75,
    qrCode: 'UC005',
  ),
  TourLocation(
    id: 'auditorium',
    title: 'Auditorium',
    subtitle: 'Events and assemblies',
    description: 'Venue for university events, seminars and assemblies.',
    hours: 'Open during scheduled events',
    distanceMeters: 150,
    qrCode: 'UC006',
  ),
  TourLocation(
    id: 'registrar',
    title: 'Registrar',
    subtitle: 'Records and enrolment',
    description: 'Enrolment, transcripts and student records requests.',
    hours: 'Open 8:00 AM – 5:00 PM',
    distanceMeters: 90,
    qrCode: 'UC003',
  ),
];
