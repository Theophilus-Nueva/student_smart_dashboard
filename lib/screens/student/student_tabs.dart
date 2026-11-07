import 'package:flutter/material.dart';

import '../shared/placeholder_screen.dart';

/// Student tab roots: Home, Analytics, Device, Settings.
List<Widget> studentTabs() => const [
  PlaceholderScreen(title: 'Student Home'),
  PlaceholderScreen(title: 'Analytics'),
  PlaceholderScreen(title: 'Device'),
  PlaceholderScreen(title: 'Settings'),
];
