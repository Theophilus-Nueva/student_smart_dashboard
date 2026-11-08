import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/screens/shared/ar_guide_screen.dart';

import 'test_helpers.dart';

void main() {
  for (final (user, password) in [
    ('student', 'student123'),
    ('faculty', 'faculty123'),
  ]) {
    testWidgets('AR Guide button on Home opens the guide for $user', (
      tester,
    ) async {
      await pumpApp(tester);
      await signInAs(tester, user, password);

      expect(find.byTooltip('Launch AR Guide'), findsOneWidget);
      await tester.tap(find.text('AR Guide'));
      await tester.pumpAndSettle();

      expect(find.byType(ArGuideScreen), findsOneWidget);
      expect(find.text('AR Campus Guide'), findsOneWidget);
      expect(find.text('Faculty access only'), findsNothing);
    });
  }

  testWidgets('Labels follow the compass and the route panel shows progress', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tester.tap(find.text('AR Guide'));
    await tester.pumpAndSettle();

    // FakeSensors point the phone east (90°): Computer Laboratory (120°) is
    // in view; Main Building (0°), the first stop, is off to the left.
    expect(find.text('E · 90°'), findsOneWidget);
    expect(find.text('↑ Computer Laboratory (120m)'), findsOneWidget);
    expect(find.text('↑ Main Building (20m)'), findsNothing);
    expect(find.text('Next: ← Main Building'), findsOneWidget);

    expect(find.text('Start at Main Building'), findsOneWidget);
    expect(find.text('0 / 5 locations · 0%'), findsOneWidget);
    expect(find.text('Pending Visit Uploads: 0'), findsOneWidget);

    // Tapping a label shows its details.
    await tester.tap(find.text('↑ Computer Laboratory (120m)'));
    await tester.pumpAndSettle();
    expect(find.text('Open Location Details'), findsOneWidget);
    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();

    // Leaving the guide stops the sensors.
    await tester.tap(find.byTooltip('Close AR guide'));
    await tester.pumpAndSettle();
    expect(services.device.sensorsRunning, isFalse);
  });

  test('Checkpoint codes map to locations and advance the route', () async {
    final services = await makeServices();
    final tour = services.tour;

    expect(tour.byQrCode('uc002 ')?.title, 'Library');
    expect(tour.byQrCode('UC999'), isNull);
    expect(tour.routeStops.map((l) => l.title), [
      'Main Building',
      'Library',
      'Computer Laboratory',
      'Student Center',
      'Auditorium',
    ]);

    await tour.recordVisit(tour.byQrCode('UC001')!.id);
    await tour.recordVisit(tour.byQrCode('UC002')!.id);
    expect(tour.routeVisitedCount, 2);
    expect(tour.routeProgress, closeTo(0.4, 1e-9));
    expect(tour.currentRouteStop?.title, 'Library');
    expect(tour.nextRouteStop?.title, 'Computer Laboratory');
  });

  test('Angle difference wraps around north', () {
    expect(arAngleDiff(10, 350), 20);
    expect(arAngleDiff(350, 10), -20);
    expect(arAngleDiff(120, 90), 30);
  });
}
