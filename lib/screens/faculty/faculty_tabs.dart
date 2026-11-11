import 'package:flutter/material.dart';

import '../../auth/role_guard.dart';
import '../shared/device_screen.dart';
import 'class_analytics.dart';
import 'faculty_home.dart';
import 'faculty_settings.dart';
import '../../config/lab_week.dart';
import '../shared/placeholder_screen.dart';

/// Faculty tab roots: Home, Class Analytics, Device, Settings.
/// Faculty-only tabs are wrapped in [FacultyOnly] as a second check.
/// The Device tab is a placeholder before Week 5 (Week 1 allows placeholders).
List<Widget> facultyTabs() => [
  const FacultyOnly(screenName: 'Faculty Home', child: FacultyHome()),
  const FacultyOnly(screenName: 'Class Analytics', child: ClassAnalytics()),
  Feature.device.on
      ? const DeviceScreen()
      : const PlaceholderScreen(title: 'Device', showAppBar: true),
  const FacultyOnly(screenName: 'Faculty Settings', child: FacultySettings()),
];
