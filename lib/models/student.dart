/// Student record (Week 3 form fields + Week 4 grade, Week 7 `synced` flag).
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.program,
    required this.yearLevel,
    required this.grade,
    this.contact = '',
    this.address = '',
    this.synced = false,
  });

  static const programs = ['BSIT', 'BSCS', 'BSIS'];
  static const yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  final String id;
  final String name;
  final String email;
  final String program;
  final String yearLevel;
  final double grade;
  final String contact;
  final String address;
  final bool synced;

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? program,
    String? yearLevel,
    double? grade,
    String? contact,
    String? address,
    bool? synced,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      grade: grade ?? this.grade,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'program': program,
    'yearLevel': yearLevel,
    'grade': grade,
    'contact': contact,
    'address': address,
    'synced': synced,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String? ?? '',
    program: json['program'] as String? ?? 'BSIT',
    yearLevel: json['yearLevel'] as String? ?? '1st Year',
    grade: (json['grade'] as num?)?.toDouble() ?? 0,
    contact: json['contact'] as String? ?? '',
    address: json['address'] as String? ?? '',
    synced: json['synced'] as bool? ?? false,
  );

  /// `student_info.txt` format from the Week 3 lab.
  String toExportText() =>
      'STUDENT INFORMATION\n\n'
      'Name: $name\n'
      'ID: $id\n'
      'Program: $program\n'
      'Year: $yearLevel\n'
      'Email: $email\n';
}

/// Sample records from the Figma prototype (invented data).
const sampleStudents = <Student>[
  Student(
    id: '2024-1-00123',
    name: 'Dela Cruz, Juan',
    email: 'juan.delacruz@lpu.example',
    program: 'BSIT',
    yearLevel: '3rd Year',
    grade: 89.0,
    contact: '+63 912 345 6701',
    address: 'Imus, Cavite',
    synced: true,
  ),
  Student(
    id: '2024-2-00210',
    name: 'Garcia, Jose',
    email: 'jose.garcia@lpu.example',
    program: 'BSIS',
    yearLevel: '2nd Year',
    grade: 84.3,
    contact: '+63 912 345 6702',
    address: 'Dasmariñas, Cavite',
    synced: true,
  ),
  Student(
    id: '2024-1-00145',
    name: 'Lopez, Maria',
    email: 'maria.lopez@lpu.example',
    program: 'BSCS',
    yearLevel: '2nd Year',
    grade: 97.5,
    contact: '+63 912 345 6711',
    address: 'Cavite, Philippines',
    synced: true,
  ),
  Student(
    id: '2024-2-02401',
    name: 'Nueva, Theophilus T.',
    email: 'theophilus.nueva@lpu.example',
    program: 'BSIT',
    yearLevel: '3rd Year',
    grade: 91.2,
    contact: '+63 912 345 6789',
    address: 'Cavite, Philippines',
    synced: true,
  ),
  Student(
    id: '2025-1-00302',
    name: 'Torres, Mark',
    email: 'mark.torres@lpu.example',
    program: 'BSCS',
    yearLevel: '1st Year',
    grade: 78.6,
    contact: '+63 912 345 6712',
    address: 'General Trias, Cavite',
    synced: true,
  ),
];
