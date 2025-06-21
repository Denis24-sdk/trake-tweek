// Example widget test adapted for your project structure:

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_productivity_hub/main.dart';

void main() {
  testWidgets('Dashboard page renders correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar title is displayed
    expect(find.text('Pro Productivity Hub'), findsOneWidget);

    // Verify the dashboard icon (Hero widget)
    expect(find.byIcon(Icons.dashboard), findsWidgets);
  });
}