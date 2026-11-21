import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';
import 'package:smart_dashboard/services/notification_service.dart';

import 'package:smart_dashboard/widgets/common.dart';
import 'package:smart_dashboard/widgets/compass_sheet.dart';
import 'package:smart_dashboard/widgets/slide_up_sheet.dart';

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
    // Recent still below the bottom edge.
    expect(tester.getRect(find.byType(CompassDial)).top, greaterThan(0));
    expect(tester.getRect(find.text('90°  E')).bottom, lessThan(844));
    expect(tester.getRect(recent).top, greaterThanOrEqualTo(844));
    // Same look as the Map panel: gray handle, no Material handle.
    expect(find.byKey(const Key('slideUp.handle')), findsOneWidget);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isNot(true),
    );
    final panel = find.byType(SlideUpPanel);
    final peekTop = tester.getRect(panel).top;

    // Drag up from the dial (not the handle): the sheet grows to show
    // Recent, like the Map panel.
    await tester.drag(find.byType(CompassDial), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(panel).top, lessThan(peekTop));
    expect(tester.getRect(recent).bottom, lessThan(844));
    expect(
      find.descendant(of: recent, matching: find.text('E')),
      findsOneWidget,
    );
    expect(find.textContaining('Recent:'), findsNothing);
    final rotation = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byType(CompassDial),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(rotation.turns, closeTo(-0.25, 1e-9)); // dial turns -90°

    // A small drag down springs back; the sheet stays open.
    await tester.drag(
      find.descendant(of: panel, matching: find.text('Compass')),
      const Offset(0, 60),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CompassDial), findsOneWidget);

    // A long drag down from anywhere on it closes it.
    await tester.drag(find.byType(CompassDial), const Offset(0, 800));
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
    // The accelerometer graph still animates.
    expect(chart.duration, const Duration(milliseconds: 250));
    expect(find.text('Movement history'), findsOneWidget);

    // Like every slide-up: a small drag down springs back, a flick down
    // from anywhere on it closes it, and so does a tap outside.
    await tester.drag(find.text('Movement history'), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    await tester.fling(
      find.text('Movement history'),
      const Offset(0, 300),
      2000,
    );
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    await tester.tap(find.byKey(const Key('device.accelerometer')));
    await tester.pumpAndSettle();
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
    // Gyroscope graph only: no animation between readings.
    expect(chart.duration, Duration.zero);
    expect(find.text('Last 30 seconds'), findsOneWidget);

    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('Map fills the screen with a slide-up details panel', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.map);

    // The map spans the whole body, edge to edge, under the app bar.
    final panel = find.byKey(const Key('map.info'));
    final body = tester.getRect(
      find.ancestor(of: panel, matching: find.byType(Stack)).first,
    );
    expect(body.left, 0);
    expect(body.width, 390);
    expect(body.bottom, 844);
    // Collapsed: the address shows, the coordinates are below the screen.
    expect(tester.getRect(find.text('Current location')).bottom, lessThan(844));
    expect(tester.getRect(find.text('Latitude')).top, greaterThan(844));
    // Drag the panel up: the coordinates and markers come into view.
    await tester.drag(find.text('Current location'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Latitude')).bottom, lessThan(844));
    expect(panel, findsOneWidget);
    // Never covers the whole map.
    expect(tester.getRect(find.text('Current location')).top, greaterThan(150));
  });

  testWidgets('Map panel fits in landscape', (tester) async {
    await pumpApp(tester, size: const Size(844, 390), sidePadding: 59);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.map);
    expect(find.text('Current location'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The panel's text keeps clear of the notch.
    expect(tester.getRect(find.text('Current location')).left, greaterThan(59));
  });

  testWidgets('Compass sheet follows the finger while readings arrive', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Device');

    // Drags the sheet up 150 px and holds it, optionally while sensor
    // readings arrive (they rebuild the sheet many times a second on a
    // phone). Returns how far the sheet moved.
    Future<double> dragUp({required bool readings}) async {
      await openCompassSheet(tester);
      final panel = find.byType(SlideUpPanel);
      final start = tester.getRect(panel).top;
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(CompassDial)),
      );
      for (var i = 0; i < 25; i++) {
        if (i < 15) await finger.moveBy(const Offset(0, -10));
        if (readings) services.device.notifyListeners();
        await tester.pump(const Duration(milliseconds: 16));
      }
      final moved = start - tester.getRect(panel).top;
      await finger.up();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 20)); // close it
      await tester.pumpAndSettle();
      return moved;
    }

    final still = await dragUp(readings: false);
    expect(still, greaterThan(100));
    // Readings arriving mid-drag no longer snap the sheet back.
    expect(await dragUp(readings: true), closeTo(still, 1));
  });

  testWidgets('Study reminder time is set in Notifications and scheduled', (
    tester,
  ) async {
    final reminders = RecordingNotifications();
    final services = await makeServices(notifications: reminders);
    await pumpApp(tester, services: services);
    await signInAs(tester, 'student', 'student123');
    // On by default at 7:00 PM, scheduled when the app starts.
    expect(reminders.daily[ReminderCategory.study], (19, 0));

    await pushRoute(tester, AppRoutes.notifications);
    expect(find.text('Daily at 7:00 PM'), findsOneWidget);
    // The time button opens a time picker; OK keeps and schedules it.
    await tester.tap(find.byKey(const Key('settings.studyTime')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.text('Study reminder time'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text('Study reminder set for 7:00 PM every day.'),
      findsOneWidget,
    );

    // A new time moves the daily reminder.
    await services.settings.setStudyReminderTime(20, 30);
    await services.syncStudyReminder();
    await tester.pumpAndSettle();
    expect(find.text('Daily at 8:30 PM'), findsOneWidget);
    expect(reminders.daily[ReminderCategory.study], (20, 30));

    // Turning it off cancels it and disables the time button.
    final toggle = find.ancestor(
      of: find.text('Study Reminders'),
      matching: find.byType(ToggleRow),
    );
    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(reminders.daily.containsKey(ReminderCategory.study), isFalse);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('settings.studyTime')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('On iPhone the study time uses the iOS wheel picker', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final reminders = RecordingNotifications();
      final services = await makeServices(notifications: reminders);
      await pumpApp(tester, services: services);
      await signInAs(tester, 'student', 'student123');
      await pushRoute(tester, AppRoutes.notifications);
      await tester.tap(find.byKey(const Key('settings.studyTime')));
      await tester.pumpAndSettle();
      // iOS wheel, not the Material clock dialog.
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(TimePickerDialog), findsNothing);
      await tester.tap(find.byKey(const Key('timePicker.done')));
      await tester.pumpAndSettle();
      expect(reminders.daily[ReminderCategory.study], (19, 0));
      expect(
        find.text('Study reminder set for 7:00 PM every day.'),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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
