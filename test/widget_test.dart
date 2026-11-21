import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';
import 'package:smart_dashboard/services/app_settings.dart';
import 'package:smart_dashboard/services/biometric_service.dart';
import 'package:smart_dashboard/widgets/network_status.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Login shows the app name and password sign-in', (tester) async {
    await pumpApp(tester);
    expect(find.text('Smart Campus Tour Guide'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    // No biometric button until it is set up in Settings.
    expect(find.byKey(const Key('login.biometric')), findsNothing);
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

  testWidgets('Biometric login stays hidden until set up in Settings', (
    tester,
  ) async {
    // The phone has Face ID, but it hasn't been turned on in the app.
    await pumpApp(
      tester,
      services: await makeServices(biometric: const AcceptingBiometric()),
    );
    expect(find.byKey(const Key('login.biometric')), findsNothing);
    expect(find.textContaining('Face ID'), findsNothing);
  });

  testWidgets('Face ID without a remembered account explains why', (
    tester,
  ) async {
    await pumpApp(
      tester,
      services: await makeServices(
        prefs: {'settings.biometricLogin': true},
        biometric: const AcceptingBiometric(),
      ),
    );
    // Named after what the phone has: Face ID, not fingerprint.
    expect(find.text('Sign in with Face ID'), findsOneWidget);
    expect(find.textContaining('fingerprint'), findsNothing);
    await tester.tap(find.text('Sign in with Face ID'));
    await tester.pumpAndSettle();
    expect(find.text('Face ID Required'), findsOneWidget);
    // The app's standard slide-up: gray handle, draggable from anywhere.
    expect(find.byKey(const Key('slideUp.handle')), findsOneWidget);
    await tester.tap(find.byTooltip('Use Face ID'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sign in with your password once to use Face ID.'),
      findsOneWidget,
    );
  });

  testWidgets('Set up Touch ID in Settings, then sign in with it', (
    tester,
  ) async {
    final services = await makeServices(
      biometric: const AcceptingBiometric(BiometricKind.touchId),
    );
    await pumpApp(tester, services: services);
    await signInAs(tester, 'faculty', 'faculty123');

    // Settings › Security Center: one toggle, named after the phone's own
    // biometric, off until turned on (which asks for Touch ID once).
    await tapNav(tester, 'Settings');
    final toggle = find.byKey(const Key('settings.biometric'));
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Touch ID'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(
            find.descendant(of: toggle, matching: find.byType(Switch)),
          )
          .value,
      isFalse,
    );
    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Touch ID sign-in is on.'), findsOneWidget);
    expect(services.settings.get(AppSettings.biometricLogin), isTrue);

    // Signed out: the Touch ID sheet opens by itself for the last account.
    services.session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Touch ID Required'), findsOneWidget);
    await tester.tap(find.byTooltip('Use Touch ID'));
    await tester.pumpAndSettle();
    expect(services.session.user?.displayName, 'Pocaan, Alyssa Paola D.');
    expect(services.session.method, 'Touch ID');
  });

  testWidgets('Settings explains when the phone has no biometrics', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInAs(tester, 'student', 'student123');
    await tapNav(tester, 'Settings');
    final toggle = find.byKey(const Key('settings.biometric'));
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No Face ID or fingerprint'), findsOneWidget);
    final sw = tester.widget<Switch>(
      find.descendant(of: toggle, matching: find.byType(Switch)),
    );
    expect(sw.onChanged, isNull); // can't be turned on
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
