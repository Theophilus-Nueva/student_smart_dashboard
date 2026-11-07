import 'package:flutter/material.dart';

import '../screens/auth/access_denied_screen.dart';
import '../services/app_services.dart';

/// Wraps every faculty-only screen. A student who reaches one (by route or
/// by a stale link) sees Access Denied instead of the screen.
class FacultyOnly extends StatelessWidget {
  const FacultyOnly({super.key, required this.screenName, required this.child});

  final String screenName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.isFaculty
          ? child
          : AccessDeniedScreen(screenName: screenName),
    );
  }
}
