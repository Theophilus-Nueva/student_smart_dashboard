import 'package:flutter/material.dart';

import '../shared/device_screen.dart';
import 'student_analytics.dart';
import 'student_home.dart';
import 'student_settings.dart';
import '../../config/lab_week.dart';
import '../shared/placeholder_screen.dart';

/// Student tab roots: Home, Analytics, Device, Settings.
/// The Device tab is a placeholder before Week 5 (Week 1 allows placeholders).
List<Widget> studentTabs() => [
  const StudentHome(),
  const StudentAnalytics(),
  Feature.device.on
      ? const DeviceScreen()
      : const PlaceholderScreen(title: 'Device', showAppBar: true),
  const StudentSettings(),
];
