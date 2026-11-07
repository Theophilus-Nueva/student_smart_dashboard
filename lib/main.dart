import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Tour Guide',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const DashboardScreen(),
    );
  }
}
