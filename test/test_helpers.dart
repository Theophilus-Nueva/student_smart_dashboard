import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_dashboard/main.dart';
import 'package:smart_dashboard/services/app_services.dart';
import 'package:smart_dashboard/services/biometric_service.dart';
import 'package:smart_dashboard/services/location_service.dart';
import 'package:smart_dashboard/services/notification_service.dart';

/// Fresh services backed by in-memory SharedPreferences. The connection check
/// and documents folder are faked so tests never touch the network.
Future<AppServices> makeServices({
  Map<String, Object> prefs = const {},
  bool online = true,
  bool apiFails = false,
  BiometricService biometric = const UnavailableBiometricService(),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final services = AppServices(
    prefs: await SharedPreferences.getInstance(),
    connectionCheck: () async => online,
    connectivityChanges: () => const Stream<bool>.empty(),
    location: const SampleLocationService(),
    biometric: biometric,
    notifications: const SilentNotificationService(),
    useNativeMaps: false,
    documentsDirectory: () async => Directory.systemTemp.createTemp('scg'),
    usersFetcher: () async {
      if (apiFails) throw Exception('API Error');
      return sampleApiUsers;
    },
  );
  await services.init();
  return services;
}

/// Pumps the app on a phone-sized screen (Figma frames are 390x844).
Future<AppServices> pumpApp(
  WidgetTester tester, {
  AppServices? services,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final s = services ?? await makeServices();
  await tester.pumpWidget(SmartCampusApp(services: s));
  await tester.pumpAndSettle();
  return s;
}

Future<void> signInAs(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(find.byKey(const Key('login.username')), username);
  await tester.enterText(find.byKey(const Key('login.password')), password);
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
}

Future<void> pushRoute(
  WidgetTester tester,
  String route, {
  Object? args,
}) async {
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(route, arguments: args);
  await tester.pumpAndSettle();
}

Future<void> tapNav(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// The vertical list inside the Home "Dashboard" tab.
final homeScrollable = find
    .descendant(
      of: find.byKey(const Key('home.dashboard')),
      matching: find.byType(Scrollable),
    )
    .first;

/// Two users in the JSONPlaceholder shape.
const sampleApiUsers = <Map<String, dynamic>>[
  {
    'name': 'Leanne Graham',
    'email': 'Sincere@april.biz',
    'phone': '1-770-736-8031 x56442',
    'company': {'name': 'Romaguera-Crona'},
  },
  {
    'name': 'Ervin Howell',
    'email': 'Shanna@melissa.tv',
    'phone': '010-692-6593 x09125',
    'company': {'name': 'Deckow-Crist'},
  },
];

/// Fingerprint sensor that always accepts.
class AcceptingBiometric implements BiometricService {
  const AcceptingBiometric();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricResult> authenticate(String reason) async =>
      BiometricResult.success;
}
