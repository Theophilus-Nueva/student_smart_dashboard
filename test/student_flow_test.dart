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
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('Current Location'), findsOneWidget);
    expect(find.text('Open Map'), findsOneWidget);
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
    expect(find.text('Reset Database'), findsNothing);
  });

  testWidgets('Log out returns to the login screen', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Settings');
    await tester.scrollUntilVisible(find.text('Log out'), 300);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}
