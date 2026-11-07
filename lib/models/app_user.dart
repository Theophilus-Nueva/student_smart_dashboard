enum Role { student, faculty }

extension RoleLabel on Role {
  String get label => this == Role.faculty ? 'Faculty' : 'Student';
}

/// A signed-in LPU account. The role decides which dashboard is shown.
class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.role,
    required this.idNumber,
    required this.subtitle,
  });

  final String username;
  final String displayName;
  final Role role;

  /// Student ID for students, employee ID for faculty.
  final String idNumber;

  /// Programme for students, department for faculty.
  final String subtitle;

  bool get isFaculty => role == Role.faculty;
}
