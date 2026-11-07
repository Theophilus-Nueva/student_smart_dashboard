import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' as api;

/// A JSONPlaceholder user shown in the Online Directory (Weeks 2 and 4).
class DirectoryUser {
  const DirectoryUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
  });

  final String name;
  final String email;
  final String phone;
  final String company;

  factory DirectoryUser.fromApi(Map<String, dynamic> json) => DirectoryUser(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    company:
        (json['company'] as Map<String, dynamic>?)?['name'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'company': {'name': company},
  };
}

typedef UsersFetcher = Future<List<dynamic>> Function();

/// Loads the API users, keeps the last good list for offline use, and
/// tracks loading / error / last-updated state.
class DirectoryService extends ChangeNotifier {
  DirectoryService(this._prefs, {UsersFetcher? fetcher})
    : _fetcher = fetcher ?? api.getUsers;

  static const _cacheKey = 'directory.cache';
  static const _updatedKey = 'directory.updated';

  final SharedPreferences _prefs;
  final UsersFetcher _fetcher;

  List<DirectoryUser> _users = [];
  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;

  List<DirectoryUser> get users => List.unmodifiable(_users);
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get hasData => _users.isNotEmpty;

  // Week 2 summary stats.
  int get totalCompanies => _users.map((u) => u.company).toSet().length;
  int get totalEmails => _users.where((u) => u.email.isNotEmpty).length;
  int get totalPhones => _users.where((u) => u.phone.isNotEmpty).length;

  void load() {
    final raw = _prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        _users = (jsonDecode(raw) as List<dynamic>)
            .map((e) => DirectoryUser.fromApi(e as Map<String, dynamic>))
            .toList();
      } on FormatException {
        _users = [];
      }
    }
    final updated = _prefs.getString(_updatedKey);
    _lastUpdated = updated == null ? null : DateTime.tryParse(updated);
  }

  /// Returns true on success.
  Future<bool> refresh() async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _fetcher();
      _users = data
          .map((e) => DirectoryUser.fromApi(e as Map<String, dynamic>))
          .toList();
      _lastUpdated = DateTime.now();
      await _prefs.setString(
        _cacheKey,
        jsonEncode(_users.map((u) => u.toJson()).toList()),
      );
      await _prefs.setString(_updatedKey, _lastUpdated!.toIso8601String());
      return true;
    } on Object {
      _error = 'API Error';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<DirectoryUser> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return _users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.company.toLowerCase().contains(q),
        )
        .toList();
  }
}
