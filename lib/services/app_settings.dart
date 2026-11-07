import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On/off preferences from the Settings tab.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  static const fingerprintLogin = 'settings.fingerprintLogin';
  static const faceAuth = 'settings.faceAuth';
  static const studyReminders = 'settings.studyReminders';
  static const assignmentReminders = 'settings.assignmentReminders';
  static const dailyCheckIn = 'settings.dailyCheckIn';
  static const autoRefresh = 'settings.autoRefresh';

  static const _defaults = {
    fingerprintLogin: true,
    faceAuth: false,
    studyReminders: true,
    assignmentReminders: true,
    dailyCheckIn: false,
    autoRefresh: true,
  };

  bool get(String key) => _prefs.getBool(key) ?? _defaults[key] ?? false;

  Future<void> set(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
  }
}

/// Device shown in Settings › Logged in device. There is no device-info
/// package in the labs, so this is the Week 1 example device.
const sampleDeviceName = 'Samsung Galaxy A54';
const sampleDeviceDetail = 'Android 14 · Online · this device';
