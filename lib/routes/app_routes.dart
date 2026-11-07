import 'package:flutter/material.dart';

import '../auth/role_guard.dart';
import '../screens/faculty/online_directory_screen.dart';
import '../screens/faculty/student_details_screen.dart';
import '../screens/faculty/student_form_screen.dart';
import '../screens/faculty/student_records_screen.dart';
import '../screens/shared/about_lpu_screen.dart';
import '../screens/shared/campus_tour_screen.dart';
import '../screens/shared/cloud_tasks_screen.dart';
import '../screens/shared/emergency_contacts_screen.dart';
import '../screens/shared/faculty_directory_screen.dart';
import '../screens/shared/file_saved_screen.dart';
import '../screens/shared/location_detail_screen.dart';
import '../screens/shared/map_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/placeholder_screen.dart';
import '../screens/student/my_record_screen.dart';
import '../services/file_export_service.dart';

/// Named routes for pushed screens (tab roots live in the role shell).
class AppRoutes {
  AppRoutes._();

  // Faculty only.
  static const studentRecords = '/faculty/students';
  static const studentForm = '/faculty/students/form';
  static const studentDetails = '/faculty/students/details';
  static const onlineDirectory = '/faculty/online-directory';

  // Student only (own data).
  static const myRecord = '/student/record';

  // Shared.
  static const fileSaved = '/file-saved';
  static const about = '/about';
  static const campusTour = '/tour';
  static const locationDetail = '/tour/location';
  static const map = '/map';
  static const cloudTasks = '/cloud-tasks';
  static const notifications = '/notifications';
  static const emergencyContacts = '/emergency-contacts';
  static const facultyDirectory = '/faculty-directory';

  /// Screen titles, also used by Access Denied ("<title> is only available…").
  static const titles = <String, String>{
    studentRecords: 'Student Records',
    studentForm: 'Add Student',
    studentDetails: 'Student Details',
    onlineDirectory: 'Online Directory',
    myRecord: 'My Record',
    fileSaved: 'File Saved',
    about: 'About LPU',
    campusTour: 'Campus Tour',
    locationDetail: 'Location Detail',
    map: 'Map',
    cloudTasks: 'Cloud Tasks',
    notifications: 'Notifications',
    emergencyContacts: 'Emergency Contacts',
    facultyDirectory: 'Faculty Directory',
  };

  static const facultyOnly = {
    studentRecords,
    studentForm,
    studentDetails,
    onlineDirectory,
  };

  static Widget _screenFor(String name, Object? args, String title) {
    return switch (name) {
      studentRecords => const StudentRecordsScreen(),
      studentForm => StudentFormScreen(studentId: args as String?),
      studentDetails when args is String => StudentDetailsScreen(
        studentId: args,
      ),
      onlineDirectory => const OnlineDirectoryScreen(),
      myRecord => const MyRecordScreen(),
      about => const AboutLpuScreen(),
      campusTour => const CampusTourScreen(),
      locationDetail when args is String => LocationDetailScreen(
        locationId: args,
      ),
      map => const MapScreen(),
      cloudTasks => const CloudTasksScreen(),
      notifications => const NotificationsScreen(),
      emergencyContacts => const EmergencyContactsScreen(),
      facultyDirectory => const FacultyDirectoryScreen(),
      fileSaved when args is ExportResult => FileSavedScreen(result: args),
      _ => PlaceholderScreen(title: title),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final title = titles[name];
    if (name == null || title == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        final screen = _screenFor(name, settings.arguments, title);
        return facultyOnly.contains(name)
            ? FacultyOnly(screenName: title, child: screen)
            : screen;
      },
    );
  }
}
