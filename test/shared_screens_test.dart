import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';

import 'package:smart_dashboard/widgets/common.dart';
import 'package:smart_dashboard/widgets/compass_sheet.dart';

import 'test_helpers.dart';

const _sharedRoutes = {
  AppRoutes.about: 'Vision',
  AppRoutes.campusTour: 'Campus Locations',
  AppRoutes.map: 'Markers',
  AppRoutes.cloudTasks: 'No tasks yet',
  AppRoutes.notifications: 'Send Test Notification',
  AppRoutes.emergencyContacts: 'Call Security',
  AppRoutes.facultyDirectory: 'Prof. Maria Santos',
};

Future<void> openCompassSheet(WidgetTester tester) async {
  final card = find.byKey(const Key('device.compass'));
  await tester.scrollUntilVisible(
    card,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  for (final (user, password) in [
    ('student', 'student123'),
    ('faculty', 'faculty123'),
  ]) {
    testWidgets('Every shared screen opens for $user', (tester) async {
      await pumpApp(tester);
      await signInAs(tester, user, password);
      for (final MapEntry(key: route, value: text) in _sharedRoutes.entries) {
        await pushRoute(tester, route);
        expect(find.text(text), findsWidgets, reason: route);
        expect(find.text('Faculty access only'), findsNothing, reason: route);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('Recording a visit updates tour progress and history', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.locationDetail, args: 'library');

    await tester.tap(find.text('Record Visit'));
    await tester.pumpAndSettle();
    expect(services.tour.visitedCount, 1);
    expect(services.tour.isVisited('library'), isTrue);
    expect(find.textContaining('Visited today'), findsOneWidget);

    await tester.tap(find.text('Bookmark'));
    await tester.pumpAndSettle();
    expect(services.tour.isBookmarked('library'), isTrue);
  });

  testWidgets('Cloud Tasks adds, completes and deletes a task', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.cloudTasks);

    await tester.enterText(
      find.byKey(const Key('tasks.input')),
      'Prepare Lab Report',
    );
    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Prepare Lab Report'), findsOneWidget);
    expect(services.tasks.totalCount, 1);
    // Auto-sync is on and we are online, so the task is uploaded.
    expect(services.sync.pendingCount, 0);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(services.tasks.completedCount, 1);

    await tester.tap(find.byTooltip('Delete task'));
    await tester.pumpAndSettle();
    expect(services.tasks.totalCount, 0);
  });

  testWidgets('Test notification is logged and shown', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.notifications);
    await tester.tap(find.text('Send Test Notification'));
    await tester.pumpAndSettle();
    expect(
      find.text('Dashboard Reminder\nYou have pending tasks'),
      findsOneWidget,
    );
    expect(services.activity.items.first.title, 'Dashboard Reminder');
    expect(services.activity.unreadCount, 0);
  });

  testWidgets('Device tab shows live sensor readings', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Accelerometer'), findsWidgets);
    // Fake readings: accelerometer Z, compass pointing east.
    expect(find.text('9.81'), findsOneWidget);
    expect(find.text('E · 90°'), findsOneWidget);
    // Status shows only in the Sensor Status card (Camera, Accelerometer,
    // Gyroscope, Compass), not beside each section title.
    expect(
      find.descendant(
        of: find.byType(SectionHeader),
        matching: find.text('Active'),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Sensor Status'),
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsNWidgets(4));

    await tapNav(tester, 'Home');
    expect(services.device.sensorsRunning, isFalse);
  });

  testWidgets('Tapping the compass slides up a dial that follows the heading', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    await openCompassSheet(tester);

    expect(find.byType(CompassDial), findsOneWidget);
    // Fake heading: top of the phone pointing east (90°).
    expect(find.text('90°  E'), findsOneWidget);
    // Recent directions live at the bottom of the sheet, not on the card.
    final recent = find.byKey(const Key('compass.recent'));
    // Opens only as tall as the compass: dial and reading on screen,
    // Recent still below the bottom edge until you scroll.
    expect(tester.getRect(find.byType(CompassDial)).top, greaterThan(0));
    expect(tester.getRect(find.text('90°  E')).bottom, lessThan(844));
    expect(tester.getRect(recent).top, greaterThanOrEqualTo(844));
    final sheet = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Material),
        )
        .first;
    final sheetTop = tester.getRect(sheet).top;
    await tester.scrollUntilVisible(
      recent,
      100,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.descendant(of: recent, matching: find.text('E')),
      findsOneWidget,
    );
    // The content scrolled; the sheet itself stayed the same height.
    expect(tester.getRect(sheet).top, sheetTop);
    expect(find.textContaining('Recent:'), findsNothing);
    final rotation = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byType(CompassDial),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(rotation.turns, closeTo(-0.25, 1e-9)); // dial turns -90°

    // A hard swipe down on the content only scrolls; the sheet stays open.
    await tester.fling(find.byType(CompassDial), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CompassDial), const Offset(0, 600), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(CompassDial), findsOneWidget);

    // Dragging the handle (top strip of the sheet) down closes it.
    final top = tester.getRect(sheet).top;
    await tester.dragFrom(Offset(195, top + 20), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byType(CompassDial), findsNothing);

    // So does a tap outside it.
    await openCompassSheet(tester);
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.byType(CompassDial), findsNothing);
  });

  testWidgets('Tapping the accelerometer slides up its values and graph', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    // The old one-line history is gone from the Device tab.
    expect(find.textContaining('Movement (X)'), findsNothing);

    await tester.tap(find.byKey(const Key('device.accelerometer')));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    // Live values (latest fake reading) and the graph of both readings.
    expect(
      tester.widget<Text>(find.byKey(const Key('accel.value.Z'))).data,
      '9.81',
    );
    expect(find.byKey(const Key('accel.graph')), findsOneWidget);
    // fl_chart line chart: one line per axis, one point per reading.
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData, hasLength(3));
    expect(chart.data.lineBarsData.first.spots, hasLength(2));
    expect(find.text('Movement history'), findsOneWidget);

    // Like the compass: a swipe on the content doesn't close it, a tap
    // outside does.
    await tester.fling(
      find.byKey(const Key('accel.graph')),
      const Offset(0, 600),
      2000,
    );
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('Tapping the gyroscope slides up its values and graph', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    final section = find.byKey(const Key('device.gyroscope'));
    await tester.scrollUntilVisible(
      section,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.pumpAndSettle();
    await tester.tap(section);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    expect(find.text('Gyroscope'), findsWidgets);
    expect(find.text('Rotation history'), findsOneWidget);
    // Latest fake reading, with the previous one and the highest under it.
    expect(
      tester.widget<Text>(find.byKey(const Key('gyro.value.X'))).data,
      '0.01',
    );
    expect(
      find.descendant(of: sheet, matching: find.text('prev 0.50')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('max 0.50')),
      findsOneWidget,
    );
    final chart = tester.widget<LineChart>(
      find.descendant(
        of: find.byKey(const Key('gyro.graph')),
        matching: find.byType(LineChart),
      ),
    );
    expect(chart.data.lineBarsData, hasLength(3));
    expect(chart.data.lineBarsData.first.spots, hasLength(2));
    // 150 readings five a second: a 30-second window.
    expect(chart.data.maxX, 149);
    expect(find.text('Last 30 seconds'), findsOneWidget);

    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('Compass dial turns the short way across north', (tester) async {
    Future<double> turnsAt(double heading) async {
      await tester.pumpWidget(MaterialApp(home: CompassDial(heading: heading)));
      return tester
          .widget<AnimatedRotation>(find.byType(AnimatedRotation))
          .turns;
    }

    expect(await turnsAt(350), closeTo(-350 / 360, 1e-9));
    // 350° → 10° is 20° clockwise, not 340° back the other way.
    expect(await turnsAt(10), closeTo(-370 / 360, 1e-9));
    expect(await turnsAt(340), closeTo(-340 / 360, 1e-9));
  });

  testWidgets('Compass sheet fits in landscape', (tester) async {
    await pumpApp(tester, size: const Size(844, 390), sidePadding: 59);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');
    await openCompassSheet(tester);
    expect(find.byType(CompassDial), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Edge to edge, so a tap at the side doesn't close it. Measures the
    // white sheet itself (the Material), not BottomSheet's outer wrapper,
    // which always fills the screen.
    final material = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Material),
        )
        .first;
    final sheet = tester.getRect(material);
    expect(sheet.left, 0);
    expect(sheet.right, 844);
    // The test font is wide enough to fill the row by itself, which hid a
    // real-device bug: the sheet must be told to fill the width, not just
    // happen to because its text is long.
    final box = tester.renderObject<RenderBox>(material);
    expect(box.constraints.minWidth, 844);
    // The dial still keeps clear of the notch.
    expect(tester.getRect(find.byType(CompassDial)).left, greaterThan(59));
    await tester.tapAt(const Offset(30, 300)); // beside the dial, inside it
    await tester.pumpAndSettle();
    expect(find.byType(CompassDial), findsOneWidget);
  });
}
