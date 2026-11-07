import 'package:flutter/material.dart';

import '../shared/device_screen.dart';
import 'student_analytics.dart';
import 'student_home.dart';
import 'student_settings.dart';

/// Student tab roots: Home, Analytics, Device, Settings.
List<Widget> studentTabs() => const [
  StudentHome(),
  StudentAnalytics(),
  DeviceScreen(),
  StudentSettings(),
];
