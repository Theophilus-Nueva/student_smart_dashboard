import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Local account check for the prototype. There is no LPU sign-in backend in
/// the labs, so two demo accounts are seeded here.
///
/// Demo accounts (prototype only, not real credentials):
///   Student  username: student   (or theophilus.nueva@lpu.example)  password: student123
///   Faculty  username: faculty   (or alyssa.pocaan@lpu.example)     password: faculty123
class AuthService {
  AuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _lastUserKey = 'auth.lastUser';
  static const _lastLoginKey = 'auth.lastLogin';

  static const _accounts = <_Account>[
    _Account(
      aliases: ['student', 'theophilus.nueva@lpu.example'],
      password: 'student123',
      user: AppUser(
        username: 'theophilus.nueva@lpu.example',
        displayName: 'Nueva, Theophilus T.',
        role: Role.student,
        idNumber: '2024-2-02401',
        subtitle: 'BS Information Technology',
      ),
    ),
    _Account(
      aliases: ['faculty', 'alyssa.pocaan@lpu.example'],
      password: 'faculty123',
      user: AppUser(
        username: 'alyssa.pocaan@lpu.example',
        displayName: 'Pocaan, Alyssa Paola D.',
        role: Role.faculty,
        idNumber: 'FAC-2019-0142',
        subtitle: 'CCS · Information Technology',
      ),
    ),
  ];

  AppUser? verify(String username, String password) {
    final name = username.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.aliases.contains(name) && account.password == password) {
        return account.user;
      }
    }
    return null;
  }

  AppUser? userFor(String username) {
    for (final account in _accounts) {
      if (account.user.username == username) return account.user;
    }
    return null;
  }

  /// The account that fingerprint login will open (last password sign-in).
  AppUser? get rememberedUser {
    final name = _prefs.getString(_lastUserKey);
    return name == null ? null : userFor(name);
  }

  DateTime? get lastLogin {
    final raw = _prefs.getString(_lastLoginKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> recordLogin(AppUser user, DateTime at) async {
    await _prefs.setString(_lastUserKey, user.username);
    await _prefs.setString(_lastLoginKey, at.toIso8601String());
  }
}

class _Account {
  const _Account({
    required this.aliases,
    required this.password,
    required this.user,
  });

  final List<String> aliases;
  final String password;
  final AppUser user;
}
