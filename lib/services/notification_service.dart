import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Week 6 notification categories (one Android channel each).
enum ReminderCategory {
  dashboard('dashboard', 'Dashboard', 'General dashboard reminders'),
  study('study_reminders', 'Study Reminders', 'Daily study reminders'),
  assignment(
    'assignment_reminders',
    'Assignment Reminders',
    'Reminders before assignments are due',
  ),
  dailyCheckIn(
    'daily_check_in',
    'Daily Check-In',
    'Reminders to record a campus visit',
  );

  const ReminderCategory(this.channelId, this.label, this.description);

  final String channelId;
  final String label;
  final String description;
}

abstract class NotificationService {
  Future<void> init();

  /// Asks for permission where the OS requires it. Returns false if denied.
  Future<bool> requestPermission();

  Future<void> show(ReminderCategory category, String title, String body);

  /// Repeats every day at [hour]:[minute] Philippine time, replacing any
  /// earlier schedule for [category].
  Future<void> scheduleDaily(
    ReminderCategory category,
    String title,
    String body, {
    required int hour,
    required int minute,
  });

  Future<void> cancelDaily(ReminderCategory category);
}

/// Reminder times are Philippine time (LPU Cavite; no daylight saving).
const reminderTimeZone = 'Asia/Manila';

/// Phone notifications via `flutter_local_notifications`.
class LocalNotificationService implements NotificationService {
  LocalNotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _nextId = 0;
  var _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready =
        await _plugin.initialize(
          settings: const InitializationSettings(
            // White pin silhouette (Android draws the status-bar icon in
            // one colour, so the full-colour app icon showed as a blob).
            android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
            // Ask on first use instead of at app start.
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        ) ??
        false;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<void> show(
    ReminderCategory category,
    String title,
    String body,
  ) async {
    await init();
    await _plugin.show(
      id: _nextId++,
      title: title,
      body: body,
      notificationDetails: _details(category),
    );
  }

  @override
  Future<void> scheduleDaily(
    ReminderCategory category,
    String title,
    String body, {
    required int hour,
    required int minute,
  }) async {
    await init();
    final zone = tz.getLocation(reminderTimeZone);
    final now = tz.TZDateTime.now(zone);
    var next = tz.TZDateTime(zone, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _dailyId(category),
      title: title,
      body: body,
      scheduledDate: next,
      notificationDetails: _details(category),
      // Inexact on Android (may come a few minutes late) so no exact-alarm
      // permission is needed; on time on iOS.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Same time every day.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDaily(ReminderCategory category) async {
    await init();
    await _plugin.cancel(id: _dailyId(category));
  }

  /// Fixed ids for the daily reminders, well clear of one-off ids.
  int _dailyId(ReminderCategory category) => 100000 + category.index;

  NotificationDetails _details(ReminderCategory category) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          category.channelId,
          category.label,
          channelDescription: category.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notify',
          // LPU red accent behind the icon in the notification list.
          color: const Color(0xFFB71C1C),
        ),
        iOS: const DarwinNotificationDetails(),
      );
}

/// No-op for widget tests.
class SilentNotificationService implements NotificationService {
  const SilentNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show(
    ReminderCategory category,
    String title,
    String body,
  ) async {}

  @override
  Future<void> scheduleDaily(
    ReminderCategory category,
    String title,
    String body, {
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDaily(ReminderCategory category) async {}
}
