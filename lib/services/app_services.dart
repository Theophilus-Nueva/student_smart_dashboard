import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';
import '../config/lab_week.dart';
import '../models/activity_item.dart';
import 'activity_log.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'biometric_service.dart';
import 'device_service.dart';
import 'directory_service.dart';
import 'file_export_service.dart';
import 'firebase_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'student_repository.dart';
import 'sync_service.dart';
import 'task_service.dart';
import 'tour_service.dart';

/// Holds every app-wide service. Created once in `main` and handed down
/// through [AppScope]; widgets listen to the individual notifiers.
class AppServices {
  AppServices({
    required this.prefs,
    BiometricService? biometric,
    NotificationService? notifications,
    ConnectionCheck? connectionCheck,
    this.connectivityChanges = deviceConnectivityChanges,
    Future<Directory> Function()? documentsDirectory,
    UsersFetcher? usersFetcher,
    FileSharer? shareFile,
    this.location = const GpsLocationService(),
    this.useNativeMaps = true,
    this.useNativeCamera = true,
    SensorSource sensors = const DeviceSensorSource(),
  }) : biometric = biometric ?? LocalAuthBiometricService(),
       notifications = notifications ?? LocalNotificationService(),
       auth = AuthService(prefs),
       directory = DirectoryService(prefs, fetcher: usersFetcher),
       settings = AppSettings(prefs),
       activity = ActivityLog(prefs),
       students = StudentRepository(prefs),
       tour = TourService(prefs),
       tasks = TaskService(prefs),
       files = FileExportService(
         documentsDirectory: documentsDirectory,
         share: shareFile,
       ),
       device = DeviceService(
         prefs,
         sensors: sensors,
         documentsDirectory: documentsDirectory,
       ) {
    session = Session(auth, this.biometric);
    sync = SyncService(prefs, [students, tour, tasks], check: connectionCheck);
  }

  final SharedPreferences prefs;
  final Stream<bool> Function() connectivityChanges;
  final BiometricService biometric;
  final NotificationService notifications;
  final AuthService auth;
  final AppSettings settings;
  final ActivityLog activity;
  final StudentRepository students;
  final TourService tour;
  final TaskService tasks;
  final FileExportService files;
  final DeviceService device;
  final DirectoryService directory;
  final LocationService location;

  /// False in widget tests, where OpenStreetMap tiles can't load (no
  /// internet).
  final bool useNativeMaps;

  /// False in widget tests, where the live camera (AR guide) can't run.
  final bool useNativeCamera;
  late final LocationTracker tracker = LocationTracker(location);
  late final Session session;
  late final SyncService sync;

  /// Keeps the phone's daily study reminder in step with Settings: on at
  /// the chosen time, or cancelled. [ask] requests notification permission
  /// first (only when the user changed something, never at start-up).
  Future<void> syncStudyReminder({bool ask = false}) async {
    if (!Feature.notifications.on) return;
    if (!settings.get(AppSettings.studyReminders)) {
      await notifications.cancelDaily(ReminderCategory.study);
      return;
    }
    if (ask && !await notifications.requestPermission()) return;
    final (hour, minute) = settings.studyReminderTime;
    await notifications.scheduleDaily(
      ReminderCategory.study,
      'Study Reminder',
      'Time to review today’s lessons.',
      hour: hour,
      minute: minute,
    );
  }

  Future<void> init() async {
    activity.load();
    students.load();
    tour.load();
    tasks.load();
    sync.load();
    directory.load();
    device.load();
    // Re-apply the daily study reminder (e.g. after an app update).
    unawaited(syncStudyReminder());

    session.onSignedIn = (user, method) => activity.add(
      ActivityKind.signIn,
      'Signed in',
      // "Password", or the biometric used ("Face ID", "Touch ID", …).
      '${method == 'password' ? 'Password' : method} · '
          '$sampleDeviceName · ${user.role.name}',
    );
    sync.onSynced = (count) => activity.add(
      ActivityKind.sync,
      'Sync completed',
      count == 1 ? '1 record uploaded' : '$count records uploaded',
    );
    sync.onConnectivityChanged = (online) => activity.add(
      ActivityKind.network,
      online ? 'Back online' : 'Went offline',
      online
          ? 'Pending records will sync now'
          : 'Changes are saved on this phone',
    );

    unawaited(notifications.init().catchError((Object _) {}));
    unawaited(sync.checkConnection());
    sync.listen(connectivityChanges());
  }
}

extension FirebaseHookup on AppServices {
  /// Call after [initFirebase] succeeds: tasks sync to Firestore and
  /// sign-ins are logged to the `logins` collection.
  void attachFirebase() {
    final remote = FirestoreTaskRemote();
    tasks.attachRemote(remote);
    final previous = session.onSignedIn;
    session.onSignedIn = (user, method) {
      previous?.call(user, method);
      unawaited(
        remote
            .logLogin(user.username, user.role.name, method)
            .catchError((Object _) {}),
      );
    };
  }
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
