import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_dashboard/main.dart';
import 'package:smart_dashboard/services/app_services.dart';

/// Fresh services backed by in-memory SharedPreferences.
Future<AppServices> makeServices([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final services = AppServices(prefs: await SharedPreferences.getInstance());
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
