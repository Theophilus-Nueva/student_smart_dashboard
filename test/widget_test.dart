import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that title is displayed.
    expect(find.text('LPU Smart Campus Dashboard'), findsOneWidget);

    // Verify bottom navigation bar items exist.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.analytics), findsOneWidget);
    expect(find.byIcon(Icons.devices), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
