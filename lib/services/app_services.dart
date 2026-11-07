import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';
import '../models/activity_item.dart';
import 'activity_log.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'biometric_service.dart';
import 'directory_service.dart';
import 'file_export_service.dart';
import 'location_service.dart';
import 'student_repository.dart';
import 'sync_service.dart';
import 'task_service.dart';
import 'tour_service.dart';

/// Holds every app-wide service. Created once in `main` and handed down
/// through [AppScope]; widgets listen to the individual notifiers.
class AppServices {
  AppServices({
    required this.prefs,
    this.biometric = const UnavailableBiometricService(),
    ConnectionCheck? connectionCheck,
    Future<Directory> Function()? documentsDirectory,
    UsersFetcher? usersFetcher,
  }) : auth = AuthService(prefs),
       directory = DirectoryService(prefs, fetcher: usersFetcher),
       settings = AppSettings(prefs),
       activity = ActivityLog(prefs),
       students = StudentRepository(prefs),
       tour = TourService(prefs),
       tasks = TaskService(prefs),
       files = FileExportService(documentsDirectory: documentsDirectory) {
    session = Session(auth, biometric);
    sync = SyncService(prefs, [students, tour, tasks], check: connectionCheck);
  }

  final SharedPreferences prefs;
  final BiometricService biometric;
  final AuthService auth;
  final AppSettings settings;
  final ActivityLog activity;
  final StudentRepository students;
  final TourService tour;
  final TaskService tasks;
  final FileExportService files;
  final DirectoryService directory;
  final LocationService location = const LocationService();
  late final Session session;
  late final SyncService sync;

  Future<void> init() async {
    activity.load();
    students.load();
    tour.load();
    tasks.load();
    sync.load();
    directory.load();

    session.onSignedIn = (user, method) => activity.add(
      ActivityKind.signIn,
      'Signed in',
      '${method == 'fingerprint' ? 'Fingerprint' : 'Password'} · '
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

    unawaited(sync.checkConnection());
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
