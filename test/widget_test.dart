import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/main.dart';
import 'package:smart_dashboard/widgets/network_status.dart';

void main() {
  testWidgets('Header and bottom nav match the design', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Smart Campus Tour Guide'), findsOneWidget);
    for (final label in ['Home', 'Analytics', 'Device', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Settings (coming soon)'), findsOneWidget);
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
