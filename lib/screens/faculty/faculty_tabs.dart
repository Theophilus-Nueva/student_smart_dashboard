import 'package:flutter/material.dart';

import '../../auth/role_guard.dart';
import '../shared/placeholder_screen.dart';

/// Faculty tab roots: Home, Class Analytics, Device, Settings.
/// Faculty-only tabs are wrapped in [FacultyOnly] as a second check.
List<Widget> facultyTabs() => const [
  PlaceholderScreen(title: 'Faculty Home'),
  FacultyOnly(
    screenName: 'Class Analytics',
    child: PlaceholderScreen(title: 'Class Analytics'),
  ),
  PlaceholderScreen(title: 'Device'),
  PlaceholderScreen(title: 'Settings'),
];
