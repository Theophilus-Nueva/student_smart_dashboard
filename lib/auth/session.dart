import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

/// The signed-in user and their role. Screens read `isFaculty` to decide
/// what to show; faculty-only routes go through `FacultyOnly`.
class Session extends ChangeNotifier {
  Session(this._auth, this._biometric);

  final AuthService _auth;
  final BiometricService _biometric;

  AppUser? _user;
  String _method = 'password';
  DateTime? _signedInAt;

  /// Called after every successful sign-in (used by the activity log).
  void Function(AppUser user, String method)? onSignedIn;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isFaculty => _user?.isFaculty ?? false;
  String get method => _method;
  DateTime? get signedInAt => _signedInAt;
  AppUser? get rememberedUser => _auth.rememberedUser;

  /// Returns an error message, or null on success.
  Future<String?> signIn(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Enter your username and password.';
    }
    final user = _auth.verify(username, password);
    if (user == null) return 'Incorrect username or password.';
    await _complete(user, 'password');
    return null;
  }

  /// Returns an error message, or null on success.
  Future<String?> signInWithFingerprint() async {
    final remembered = _auth.rememberedUser;
    if (remembered == null) {
      return 'Sign in with your password once to turn on fingerprint login.';
    }
    final result = await _biometric.authenticate(
      'Place your finger on the sensor to open Smart Campus Tour Guide.',
    );
    switch (result) {
      case BiometricResult.success:
        await _complete(remembered, 'fingerprint');
        return null;
      case BiometricResult.failed:
        return 'Fingerprint not recognised. Try again or use your password.';
      case BiometricResult.unavailable:
        return 'Fingerprint login is not available on this device yet. '
            'Use your password.';
    }
  }

  Future<void> _complete(AppUser user, String method) async {
    final now = DateTime.now();
    await _auth.recordLogin(user, now);
    _user = user;
    _method = method;
    _signedInAt = now;
    onSignedIn?.call(user, method);
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _signedInAt = null;
    notifyListeners();
  }
}
