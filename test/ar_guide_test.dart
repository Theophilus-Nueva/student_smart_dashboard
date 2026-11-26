import 'package:flutter/material.dart';
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

  testWidgets('No compass labels; the route panel shows progress', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tester.tap(find.text('AR Guide'));
    await tester.pumpAndSettle();

    // Direction labels and the compass reading were removed.
    expect(find.textContaining('↑'), findsNothing);
    expect(find.textContaining('Next: '), findsNothing);
    expect(find.text('E · 90°'), findsNothing);
    expect(services.device.sensorsRunning, isFalse);

    expect(find.text('Start at Main Building'), findsOneWidget);
    expect(find.text('0 / 5 locations · 0%'), findsOneWidget);
    expect(find.text('Pending Visit Uploads: 0'), findsOneWidget);

    await tester.tap(find.byTooltip('Close AR guide'));
    await tester.pumpAndSettle();
  });

  testWidgets('Scanning a location QR code shows its information', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tester.tap(find.text('AR Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Scan a location QR code'), findsOneWidget);

    final ar = tester.state<ArGuideScreenState>(find.byType(ArGuideScreen));
    // Same call the camera makes on each detection (about 4 per second).
    await ar.handleCode('UC002', const Rect.fromLTWH(120, 420, 150, 150));
    await tester.pumpAndSettle();

    // The card replaces the scan frame, labels and route panel.
    expect(find.text('Checkpoint UC002'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Learning and Research Center'), findsOneWidget);
    expect(find.text('Open 7:00 AM – 8:00 PM'), findsOneWidget);
    expect(find.text('Tap for Details'), findsOneWidget);
    expect(find.text('Scan a location QR code'), findsNothing);
    expect(find.text('Pending Visit Uploads: 1'), findsNothing);
    expect(services.tour.isVisited('library'), isTrue);
    expect(find.text('Library added to your visits'), findsOneWidget);

    // Tap the card for the full details.
    await tester.tap(find.text('Tap for Details'));
    await tester.pumpAndSettle();
    expect(find.text('Open Location Details'), findsOneWidget);
    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();

    // Once the code leaves the view, the card goes and the guide returns.
    await tester.pump(ArGuideScreenState.holdTime);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Checkpoint UC002'), findsNothing);
    expect(find.text('Scan a location QR code'), findsOneWidget);

    // A QR code that is not a campus checkpoint is ignored.
    await ar.handleCode('https://example.com');
    await tester.pump();
    expect(find.text('Not a campus checkpoint QR code'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  test('Checkpoint codes map to locations and advance the route', () async {
    final services = await makeServices();
    final tour = services.tour;

    expect(tour.byQrCode('uc002 ')?.title, 'Library');
    expect(tour.byQrCode('UC999'), isNull);
    // One printed code per key location (docs/qr_codes).
    expect(tour.locations.map((l) => l.qrCode).toSet(), {
      'UC001',
      'UC002',
      'UC003',
      'UC004',
      'UC005',
      'UC006',
    });
    expect(tour.routeStops.map((l) => l.title), [
      'Main Building',
      'Library',
      'Computer Laboratory',
      'Student Center',
      'Audio Visual Theater',
    ]);

    await tour.recordVisit(tour.byQrCode('UC001')!.id);
    await tour.recordVisit(tour.byQrCode('UC002')!.id);
    expect(tour.routeVisitedCount, 2);
    expect(tour.routeProgress, closeTo(0.4, 1e-9));
    expect(tour.currentRouteStop?.title, 'Library');
    expect(tour.nextRouteStop?.title, 'Computer Laboratory');
  });

  test('QR position maps to the screen in portrait and landscape', () {
    const corners = [
      Offset(700, 300),
      Offset(900, 300),
      Offset(900, 500),
      Offset(700, 500),
    ];
    // iPhone reports the image as portrait (1080 x 1920) even when the
    // phone is sideways. In landscape the size must be flipped, so the code
    // still lands on screen instead of disappearing.
    final landscape = ArGuideScreenState.codeRectOnScreen(
      corners,
      const Size(1080, 1920),
      const Size(844, 390),
    )!;
    const screen = Rect.fromLTWH(0, 0, 844, 390);
    expect(screen.contains(landscape.topLeft), isTrue);
    expect(screen.contains(landscape.bottomRight - const Offset(1, 1)), isTrue);
    // 1920 x 1080 scaled by 844 / 1920, cropped evenly top and bottom.
    const scale = 844 / 1920;
    const dy = (390 - 1080 * scale) / 2;
    expect(landscape.left, closeTo(700 * scale, 0.01));
    expect(landscape.top, closeTo(300 * scale + dy, 0.01));

    final portrait = ArGuideScreenState.codeRectOnScreen(
      const [Offset(400, 800), Offset(600, 800), Offset(600, 1000)],
      const Size(1080, 1920),
      const Size(390, 844),
    )!;
    expect(portrait.center.dx, closeTo(195, 25));

    // A code partly outside the picture still shows a box on screen.
    final edge = ArGuideScreenState.codeRectOnScreen(
      const [Offset(1900, 1000), Offset(2100, 1000), Offset(2100, 1200)],
      const Size(1080, 1920),
      const Size(844, 390),
    )!;
    expect(edge.right, lessThanOrEqualTo(844));
    expect(edge.bottom, lessThanOrEqualTo(390));
  });

  testWidgets('In landscape the card sits beside the code', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tester.tap(find.text('AR Guide'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(844, 390) * 3;
    await tester.pumpAndSettle();

    final ar = tester.state<ArGuideScreenState>(find.byType(ArGuideScreen));
    const code = Rect.fromLTWH(120, 120, 150, 150);
    await ar.handleCode('UC004', code);
    await tester.pumpAndSettle();

    final card = tester.getRect(find.text('Computer Laboratory'));
    expect(card.left, greaterThan(code.right));
    expect(tester.takeException(), isNull);
    await tester.pump(ArGuideScreenState.holdTime);
    await tester.pump(const Duration(seconds: 3));
  });
}
