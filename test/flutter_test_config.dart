import 'dart:async';

import 'package:smart_dashboard/config/lab_week.dart';

/// Runs before every test file. The feature tests check the full app
/// (Week 7) on every branch; lab_week_test.dart checks each week's view.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LabWeek.current = 7;
  await testMain();
}
