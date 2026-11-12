import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Student home shows the Figma sections in order', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('ONLINE'), findsNothing); // no status bar on Home
    expect(
      find.text('Lyceum of the Philippines University Cavite'),
      findsOneWidget,
    );
    expect(find.text('Open Map'), findsOneWidget);
    expect(find.text('Live'), findsNothing); // sample location in tests
    expect(find.text('Campus'), findsOneWidget);
    expect(find.text('Latitude'), findsNothing); // only on the Map screen
    // ID card: role and last name in capitals.
    expect(find.text('NUEVA, Theophilus T.'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);

    for (final text in [
      'Quick Actions',
      'My Record',
      '0 / 6 visited',
      'World Clock',
      'Manila',
    ]) {
      await tester.scrollUntilVisible(
        find.text(text),
        150,
        scrollable: homeScrollable,
      );
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('Recent Activity logs the sign-in', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tester.tap(find.text('Recent Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('My Record is read-only and offers export', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.myRecord);

    expect(find.textContaining('Your record is read-only'), findsOneWidget);
    expect(find.text('2024-2-02401'), findsOneWidget);
    expect(find.text('91.2'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Export to student_info.txt'),
      200,
    );
    expect(find.text('Export to student_info.txt'), findsOneWidget);
  });

  testWidgets('Export opens the Share sheet with student_info.txt', (
    tester,
  ) async {
    final shared = <String>[];
    await pumpApp(tester, services: await makeServices(sharedFiles: shared));
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.myRecord);
    final export = find.text('Export to student_info.txt');
    await tester.scrollUntilVisible(export, 200);
    await tester.tap(export);
    // The file write is real I/O, which needs real time to finish.
    for (var i = 0; i < 50 && shared.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single, endsWith('student_info.txt'));
    expect(File(shared.single).readAsStringSync(), contains('2024-2-02401'));
    expect(find.text('student_info.txt shared'), findsOneWidget);
    expect(find.text('File Saved'), findsNothing);
  });

  testWidgets('Student analytics and settings have no faculty controls', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');

    await tapNav(tester, 'Analytics');
    expect(
      find.textContaining('These are your personal stats'),
      findsOneWidget,
    );
    expect(find.text('Sync Now'), findsNothing);

    await tapNav(tester, 'Settings');
    expect(find.text('Security Center'), findsOneWidget);
    expect(find.text('Granted · Student'), findsOneWidget);
    // Profile photo instead of the red role pill.
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('Reset Database'), findsNothing);
  });

  testWidgets('Log out returns to the login screen', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Settings');
    await tester.scrollUntilVisible(find.text('Log out'), 300);
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}
