import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';

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
    expect(find.text('Active'), findsWidgets);

    await tapNav(tester, 'Home');
    expect(services.device.sensorsRunning, isFalse);
  });
}
