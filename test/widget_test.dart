import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';
import 'package:smart_dashboard/widgets/network_status.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Login shows the app name and both sign-in options', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Smart Campus Tour Guide'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with fingerprint'), findsOneWidget);
  });

  testWidgets('Wrong password shows an error', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'nope');
    expect(find.text('Incorrect username or password.'), findsOneWidget);
  });

  testWidgets('Student sign-in shows the bottom nav', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    expect(services.session.isFaculty, isFalse);
    for (final label in ['Home', 'Analytics', 'Device', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Student opening a faculty screen gets Access Denied', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');

    final context = tester.element(find.text('Home'));
    Navigator.of(context).pushNamed(AppRoutes.studentRecords);
    await tester.pumpAndSettle();

    expect(find.text('Faculty access only'), findsOneWidget);
    expect(
      find.textContaining('Student Records is only available'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Faculty access only'), findsNothing);
  });

  testWidgets('Faculty can open faculty screens', (tester) async {
    final services = await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    expect(services.session.isFaculty, isTrue);

    final context = tester.element(find.text('Home'));
    Navigator.of(context).pushNamed(AppRoutes.studentRecords);
    await tester.pumpAndSettle();
    expect(find.text('Faculty access only'), findsNothing);
  });

  testWidgets('Fingerprint without a remembered account explains why', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Sign in with fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('Fingerprint Required'), findsOneWidget);
    // The app's standard slide-up: gray handle, draggable from anywhere.
    expect(find.byKey(const Key('slideUp.handle')), findsOneWidget);
    await tester.tap(find.byTooltip('Scan fingerprint'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sign in with your password once'),
      findsOneWidget,
    );
  });

  testWidgets('Fingerprint opens the last account after a password sign-in', (
    tester,
  ) async {
    final services = await makeServices(biometric: const AcceptingBiometric());
    await pumpApp(tester, services: services);
    await signInAs(tester, 'faculty', 'faculty123');
    services.session.signOut();
    await tester.pumpAndSettle();

    // Fingerprint Login is on by default, so the sheet opens by itself.
    expect(find.text('Fingerprint Required'), findsOneWidget);
    await tester.tap(find.byTooltip('Scan fingerprint'));
    await tester.pumpAndSettle();
    expect(services.session.user?.displayName, 'Pocaan, Alyssa Paola D.');
    expect(services.session.method, 'fingerprint');
  });

  testWidgets('Network status shows the three Week 7 states', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NetworkStatusBanner(state: NetworkState.online),
              NetworkStatusBanner(state: NetworkState.pending),
              NetworkStatusBanner(state: NetworkState.offline),
            ],
          ),
        ),
      ),
    );
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('SYNC PENDING'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
  });
}
