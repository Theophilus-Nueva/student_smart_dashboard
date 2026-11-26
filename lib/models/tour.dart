import '../theme/app_assets.dart';

/// Campus location for the Week 7 tour. Merges the lab's two `TourLocation`
/// definitions (title/description/synced and qrCode/imagePath/visited).
/// The six built-in locations never change; locations people add in the app
/// ([addedByUser]) are created offline with `synced = false` and uploaded by
/// the sync service. Visit state lives in [Visit].
class TourLocation {
  const TourLocation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.hours,
    required this.distanceMeters,
    required this.qrCode,
    this.imagePath,
    this.photoFile,
    this.addedByUser = false,
    this.synced = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String hours;

  /// Estimated distance from the campus entrance until GPS is added
  /// (0 for added locations, whose distance is unknown).
  final int distanceMeters;

  /// Week 7 AR checkpoint: the text inside the location's QR code
  /// (empty for added locations, which have no printed code).
  final String qrCode;

  /// Bundled photo of the place (asset path); null until one is added.
  final String? imagePath;

  /// Photo taken or chosen in the app, saved on the phone (file path).
  final String? photoFile;

  /// Added through the Add Location form rather than built in.
  final bool addedByUser;

  /// False until uploaded (Week 7 offline queue). Built-in ones are synced.
  final bool synced;

  /// When an added location was created.
  final DateTime? createdAt;

  /// The bundled photo to show: the location's own, or the campus photo.
  /// Use `LocationPhoto` to also show [photoFile].
  String get image => imagePath ?? AppAssets.campusPhoto;

  bool get hasDistance => distanceMeters > 0;

  /// About 80 m per minute of walking.
  int get walkMinutes => (distanceMeters / 80).ceil().clamp(1, 60);

  TourLocation copyWith({bool? synced}) => TourLocation(
    id: id,
    title: title,
    subtitle: subtitle,
    description: description,
    hours: hours,
    distanceMeters: distanceMeters,
    qrCode: qrCode,
    imagePath: imagePath,
    photoFile: photoFile,
    addedByUser: addedByUser,
    synced: synced ?? this.synced,
    createdAt: createdAt,
  );

  /// Stored form of an added location.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'hours': hours,
    'photoFile': photoFile,
    'synced': synced,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory TourLocation.fromJson(Map<String, dynamic> json) => TourLocation(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? 'Added location',
    description: json['description'] as String? ?? '',
    hours: json['hours'] as String? ?? '',
    distanceMeters: 0,
    qrCode: '',
    photoFile: json['photoFile'] as String?,
    addedByUser: true,
    synced: json['synced'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
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
    imagePath: AppAssets.mainBuilding,
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
    imagePath: AppAssets.library,
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
    imagePath: AppAssets.computerLab,
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
    // id kept as 'auditorium' so visits saved before the rename still count.
    id: 'auditorium',
    title: 'Audio Visual Theater',
    subtitle: 'Seminars, talks and screenings',
    description:
        'Tiered theater with an LED wall, used for seminars, talks, '
        'screenings and university events.',
    hours: 'Open during scheduled events',
    distanceMeters: 150,
    qrCode: 'UC006',
    imagePath: AppAssets.avTheater,
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

/// Week 7 guided route (AR guide), in walking order.
const arRouteIds = [
  'main-building',
  'library',
  'computer-lab',
  'student-center',
  'auditorium',
];
