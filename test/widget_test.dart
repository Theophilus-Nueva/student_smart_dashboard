import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that title is displayed.
    expect(find.text('Student Information App'), findsOneWidget);

    // Verify bottom navigation bar items exist.
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    expect(find.byIcon(Icons.app_registration), findsOneWidget);
    expect(find.byIcon(Icons.summarize), findsOneWidget);
    expect(find.byIcon(Icons.folder), findsOneWidget);
  });
}
