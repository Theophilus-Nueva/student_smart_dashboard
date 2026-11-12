import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Faculty home shows sync status, class stats and pull to sync', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');

    expect(find.text('Sync Now'), findsNothing);

    // Pull down from the top and let go: spinner shows, then it syncs.
    await tester.fling(
      find.byKey(const Key('home.dashboard')),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Sync successful'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Sync Status sits below the ID and location cards.
    await tester.scrollUntilVisible(
      find.text('Sync Status'),
      200,
      scrollable: homeScrollable,
    );
    expect(find.text('Sync Status'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Total Students'),
      200,
      scrollable: homeScrollable,
    );
    expect(find.text('Class Overview'), findsOneWidget);
    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
  });

  testWidgets('Student Records filters by programme and searches', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.studentRecords);

    expect(find.text('5 students · sorted by name'), findsOneWidget);
    await tester.tap(find.text('BSCS'));
    await tester.pumpAndSettle();
    expect(find.text('2 students · sorted by name'), findsOneWidget);
    expect(find.text('Lopez, Maria'), findsOneWidget);
    expect(find.text('Garcia, Jose'), findsNothing);

    await tester.tap(find.text('All Students'));
    await tester.enterText(find.byType(TextField), '02401');
    await tester.pumpAndSettle();
    expect(find.text('1 student · sorted by name'), findsOneWidget);
    expect(find.text('Nueva, Theophilus T.'), findsOneWidget);
  });

  testWidgets('Online Directory uses pull to sync, not a Sync button', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.onlineDirectory);
    expect(find.byTooltip('Sync now'), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Add Student validates, then saves and lists the record', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.studentForm);

    final save = find.byKey(const Key('form.save'));
    final formList = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(save, 200, scrollable: formList);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Please enter the student name.'), findsOneWidget);
    expect(find.text('Please fill in all required fields.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('form.name')),
      -200,
      scrollable: formList,
    );
    await tester.enterText(find.byKey(const Key('form.name')), 'Reyes, Ana');
    await tester.enterText(find.byKey(const Key('form.id')), '2026-1-00007');
    await tester.enterText(
      find.byKey(const Key('form.email')),
      'ana.reyes@lpu.example',
    );
    await tester.ensureVisible(find.byKey(const Key('form.program')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form.program')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BS Library and Information Science').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('form.year')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form.year')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1st Year').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('form.grade')), '88.5');
    // Let the earlier validation SnackBar time out so it doesn't cover Save.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(save, 200, scrollable: formList);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final added = services.students.byId('2026-1-00007');
    expect(added?.name, 'Reyes, Ana');
    expect(added?.program, 'BSLIS');
    expect(added?.grade, 88.5);
  });

  testWidgets('Student Details opens, and delete asks first', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.studentDetails, args: '2024-1-00145');

    expect(find.text('Lopez, Maria'), findsOneWidget);
    expect(find.text('97.5 · Top performer'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Delete'), 200);
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete student?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(services.students.byId('2024-1-00145'), isNotNull);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(services.students.byId('2024-1-00145'), isNull);
  });

  testWidgets('Online Directory lists API users', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.onlineDirectory);

    expect(find.text('Leanne Graham'), findsOneWidget);
    expect(find.text('Romaguera-Crona'), findsOneWidget);
    // Leave the screen so its 15 s refresh timer is cancelled.
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('Online Directory shows API Error when the call fails', (
    tester,
  ) async {
    final services = await makeServices(apiFails: true);
    await pumpApp(tester, services: services);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.onlineDirectory);

    expect(find.text('API Error'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('Class Analytics and Data Management are on faculty tabs', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');

    await tapNav(tester, 'Analytics');
    expect(find.text('Class Analytics'), findsOneWidget);
    expect(find.text('Students by program'), findsOneWidget);

    await tapNav(tester, 'Settings');
    await tester.scrollUntilVisible(find.text('Reset Database'), 200);
    expect(find.text('Refresh Dashboard'), findsOneWidget);
    expect(find.text('Reset Database'), findsOneWidget);
  });

  testWidgets('A student is denied every faculty route', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    for (final route in AppRoutes.facultyOnly) {
      await pushRoute(
        tester,
        route,
        args: route == AppRoutes.studentDetails ? '2024-1-00145' : null,
      );
      expect(find.text('Faculty access only'), findsOneWidget, reason: route);
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Student Directory exports a CSV and opens the Share sheet', (
    tester,
  ) async {
    final shared = <String>[];
    await pumpApp(tester, services: await makeServices(sharedFiles: shared));
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.studentRecords);
    final export = find.text('Export to student_directory.csv');
    await tester.scrollUntilVisible(
      export,
      300,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.ensureVisible(export);
    await tester.pumpAndSettle();
    await tester.tap(export);
    // The file write is real I/O, which needs real time to finish.
    for (var i = 0; i < 50 && shared.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(shared.single, endsWith('student_directory.csv'));
    final csv = File(shared.single).readAsStringSync();
    expect(csv, startsWith('Student ID,Name,'));
    expect(csv, contains('2024-2-02401'));
    expect(find.text('student_directory.csv shared'), findsOneWidget);
  });
}
