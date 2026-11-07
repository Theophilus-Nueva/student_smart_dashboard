import 'package:flutter/material.dart';

import '../../auth/role_guard.dart';
import '../shared/placeholder_screen.dart';
import 'class_analytics.dart';
import 'faculty_home.dart';
import 'faculty_settings.dart';

/// Faculty tab roots: Home, Class Analytics, Device, Settings.
/// Faculty-only tabs are wrapped in [FacultyOnly] as a second check.
List<Widget> facultyTabs() => const [
  FacultyOnly(screenName: 'Faculty Home', child: FacultyHome()),
  FacultyOnly(screenName: 'Class Analytics', child: ClassAnalytics()),
  PlaceholderScreen(title: 'Device'),
  FacultyOnly(screenName: 'Faculty Settings', child: FacultySettings()),
];
