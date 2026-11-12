import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/config/lab_week.dart';
import 'package:smart_dashboard/routes/app_routes.dart';

import 'test_helpers.dart';

/// Shows the app as it should look for [week].
void useWeek(int week) {
  LabWeek.current = week;
  addTearDown(() => LabWeek.current = 7);
}

Finder textOnHome(String text) => find.descendant(
  of: find.byKey(const Key('home.dashboard')),
  matching: find.text(text),
);

Future<void> scrollHomeTo(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(find.text(text), 150, scrollable: homeScrollable);

Future<void> tapHomeTile(WidgetTester tester, Finder tile) async {
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  test('Every feature belongs to a week from 1 to 7', () {
    for (final f in Feature.values) {
      expect(f.week, inInclusiveRange(1, 7), reason: f.name);
      if (f.replacedIn != null) {
        expect(f.replacedIn, greaterThan(f.week), reason: f.name);
      }
    }
  });

  test('Week 1 KPI cards and tiles show in Weeks 1-6 only', () {
    for (var week = 1; week <= 7; week++) {
      useWeek(week);
      expect(Feature.kpiCards.on, week < 7, reason: 'week $week');
      expect(Feature.dashboardTiles.on, week < 7, reason: 'week $week');
    }
  });

  testWidgets('Week 1: dashboard shell only', (tester) async {
    useWeek(1);
    final services = await pumpApp(tester);
    expect(find.text('LPU Smart Campus Dashboard'), findsOneWidget);
    expect(find.text('Sign in with fingerprint'), findsNothing);

    await signInAs(tester, 'student', 'student123');
    expect(services.tracker.running, isTrue); // GPS card from Week 1
    expect(find.text('LPU Smart Campus Dashboard'), findsOneWidget);
    expect(find.text('Current Location'), findsOneWidget); // replaces GPS KPI
    expect(find.text('AR Guide'), findsNothing);

    // KPI cards: Network, API, Storage (no GPS card).
    await scrollHomeTo(tester, 'Storage');
    expect(textOnHome('Status'), findsOneWidget);
    expect(textOnHome('Connected'), findsOneWidget);
    expect(textOnHome('GPS'), findsNothing);
    expect(textOnHome('API'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home.dashboard')),
        matching: find.textContaining('Updated '),
      ),
      findsOneWidget,
    );
    expect(textOnHome('Saved on this phone'), findsOneWidget);

    // Action tiles: Device, Network, Reports, Settings; nothing later.
    await scrollHomeTo(tester, 'Reports');
    expect(textOnHome('Quick Actions'), findsOneWidget);
    expect(textOnHome('Device'), findsOneWidget);
    expect(textOnHome('Network'), findsNWidgets(2)); // KPI card and tile
    expect(textOnHome('Settings'), findsOneWidget);
    expect(textOnHome('My Record'), findsNothing);
    expect(textOnHome('Faculty Directory'), findsNothing);

    await scrollHomeTo(tester, 'World Clock');
    expect(find.text('World Clock'), findsOneWidget);

    await tapNav(tester, 'Analytics');
    expect(
      find.text('Your stats will appear here in a later lab week.'),
      findsOneWidget,
    );
    await tapNav(tester, 'Device');
    expect(find.text('Take Photo'), findsNothing);
    await tapNav(tester, 'Settings');
    expect(find.text('Security Center'), findsNothing);
    expect(find.text('About LPU'), findsNothing);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('Week 1: tiles open the tabs and check the network', (
    tester,
  ) async {
    useWeek(1);
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await scrollHomeTo(tester, 'Reports');
    await tapHomeTile(tester, textOnHome('Reports'));
    expect(
      find.text('Class stats will appear here in a later lab week.'),
      findsOneWidget,
    );

    await tapNav(tester, 'Home');
    await tapHomeTile(tester, textOnHome('Settings'));
    expect(find.text('Log out'), findsOneWidget);

    await tapNav(tester, 'Home');
    await tapHomeTile(tester, textOnHome('Device'));
    expect(
      find.text('This screen is coming in a later lab week.'),
      findsOneWidget,
    );

    await tapNav(tester, 'Home');
    await tapHomeTile(tester, textOnHome('Network').last); // the tile
    expect(find.text('You are online.'), findsOneWidget);
  });

  testWidgets('Week 1: Current Location card opens the map', (tester) async {
    useWeek(1);
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapHomeTile(tester, find.text('Open Map'));
    expect(find.textContaining('Not part of Week 1'), findsNothing);
    expect(find.textContaining('School'), findsWidgets);
  });

  testWidgets('Week 1: a later screen opened directly is a placeholder', (
    tester,
  ) async {
    useWeek(1);
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await pushRoute(tester, AppRoutes.studentRecords);
    expect(
      find.text('Not part of Week 1. This screen is added in Week 3.'),
      findsOneWidget,
    );
  });

  testWidgets('Week 2: API directory and faculty directory', (tester) async {
    useWeek(2);
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    expect(find.text('LPU Dashboard'), findsOneWidget);
    expect(find.text('Sync Status'), findsNothing);
    expect(find.text('Class Overview'), findsNothing);
    await scrollHomeTo(tester, 'Faculty Directory');
    expect(find.text('Online Directory'), findsOneWidget);
    expect(find.text('Student Records'), findsNothing);
    expect(find.text('Add Student'), findsNothing);

    await tapNav(tester, 'Analytics');
    expect(find.text('API summary'), findsOneWidget);
    expect(find.text('Students by program'), findsNothing);
  });

  testWidgets('Week 3: Student Directory lists students and adds one', (
    tester,
  ) async {
    useWeek(3);
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await scrollHomeTo(tester, 'Student Directory');
    expect(textOnHome('Add Student'), findsNothing); // not a tile any more
    expect(textOnHome('Student Records'), findsNothing);

    await tapHomeTile(tester, textOnHome('Student Directory'));
    expect(find.widgetWithText(AppBar, 'Student Directory'), findsOneWidget);
    expect(find.text('Search by student ID or name'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);

    final add = find.text('Add Student');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('form.grade')), findsNothing);

    await tester.enterText(find.byKey(const Key('form.name')), 'Reyes, Ana');
    await tester.enterText(find.byKey(const Key('form.id')), '2026-1-00007');
    await tester.enterText(
      find.byKey(const Key('form.email')),
      'ana.reyes@lpu.example',
    );
    for (final (field, option) in [
      ('form.program', 'BS Library and Information Science'),
      ('form.year', '1st Year'),
    ]) {
      await tester.ensureVisible(find.byKey(Key(field)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(field)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }
    final save = find.byKey(const Key('form.save'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Back on the directory, with the new student listed.
    expect(find.widgetWithText(AppBar, 'Student Directory'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reyes, Ana'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reyes, Ana'), findsOneWidget);
  });

  testWidgets('Week 3: student My Record without grades', (tester) async {
    useWeek(3);
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await scrollHomeTo(tester, 'About LPU');
    expect(textOnHome('My Record'), findsOneWidget);
    await pushRoute(tester, AppRoutes.myRecord);
    expect(find.text('Current Grade'), findsNothing);
  });

  testWidgets('Week 4: student management and sync status', (tester) async {
    useWeek(4);
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await scrollHomeTo(tester, 'Sync Status');
    expect(find.text('Sync Status'), findsOneWidget);
    expect(find.text('Pending records'), findsNothing); // Week 7
    await scrollHomeTo(tester, 'Student Records');
    expect(find.text('Class Overview'), findsOneWidget);
    expect(find.text('Add Student'), findsNothing);

    await tapNav(tester, 'Settings');
    expect(find.text('Data Management'), findsOneWidget);
    expect(find.text('Auto-sync when online'), findsNothing); // Week 7
    expect(find.text('Security Center'), findsNothing); // Week 6
  });

  testWidgets('Week 5: Device tab', (tester) async {
    useWeek(5);
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    expect(find.text('Take Photo'), findsOneWidget);
  });

  testWidgets('Week 6: location, fingerprint and security center', (
    tester,
  ) async {
    useWeek(6);
    final services = await pumpApp(tester);
    expect(find.text('Sign in with fingerprint'), findsOneWidget);
    await signInAs(tester, 'student', 'student123');
    expect(services.tracker.running, isTrue);
    expect(find.text('Smart Connected Dashboard'), findsOneWidget);
    expect(find.text('Current Location'), findsOneWidget);
    expect(find.text('AR Guide'), findsNothing);
    await scrollHomeTo(tester, 'Emergency Contacts');
    expect(textOnHome('Campus Tour'), findsNothing);

    await tapNav(tester, 'Settings');
    expect(find.text('Security Center'), findsOneWidget);
  });

  testWidgets('Week 7: everything, including the AR guide', (tester) async {
    useWeek(7);
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    expect(find.text('Smart Campus Tour Guide'), findsOneWidget);
    expect(find.text('AR Guide'), findsOneWidget);
    await scrollHomeTo(tester, 'Campus Tour');
    expect(textOnHome('Campus Tour'), findsWidgets);
    // The Week 1 KPI cards and tiles are replaced by the final Home.
    expect(textOnHome('Reports'), findsNothing);
    expect(textOnHome('Storage'), findsNothing);
  });

  for (var week = 1; week <= 7; week++) {
    for (final (user, password) in [
      ('student', 'student123'),
      ('faculty', 'faculty123'),
    ]) {
      testWidgets('Week $week: every tab opens for $user', (tester) async {
        useWeek(week);
        await pumpApp(tester);
        await signInAs(tester, user, password);
        for (final tab in ['Analytics', 'Device', 'Settings', 'Home']) {
          await tapNav(tester, tab);
          expect(tester.takeException(), isNull, reason: '$tab, week $week');
        }
      });
    }
  }
}
