import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';
import 'auth_service.dart';
import 'biometric_service.dart';

/// Holds every app-wide service. Created once in `main` and handed down
/// through [AppScope]; widgets listen to the individual notifiers.
class AppServices {
  AppServices({
    required this.prefs,
    BiometricService biometric = const UnavailableBiometricService(),
  }) : auth = AuthService(prefs),
       biometric = biometric {
    session = Session(auth, biometric);
  }

  final SharedPreferences prefs;
  final AuthService auth;
  final BiometricService biometric;
  late final Session session;

  Future<void> init() async {}
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
