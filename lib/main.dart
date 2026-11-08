import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/role_shell.dart';
import 'services/app_services.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await initFirebase();
  final services = AppServices(prefs: await SharedPreferences.getInstance());
  await services.init();
  if (firebaseReady) services.attachFirebase();
  runApp(SmartCampusApp(services: services));
}

class SmartCampusApp extends StatelessWidget {
  const SmartCampusApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: 'Smart Campus Tour Guide',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const AuthGate(),
      ),
    );
  }
}

/// Shows Login until someone signs in, then the shell for their role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.user;
        if (user == null) return const LoginScreen();
        return RoleShell(key: ValueKey(user.username), user: user);
      },
    );
  }
}
