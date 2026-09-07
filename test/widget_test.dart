// Basic navigation shell smoke test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gladeus/main.dart';

void main() {
  testWidgets('Navigation shell switches tabs and keeps header fixed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GladeusApp());

    // Header is present.
    expect(find.text('Welcome back'), findsOneWidget);

    // Starts on Home.
    expect(find.widgetWithText(Center, 'Home'), findsOneWidget);

    // Switch to History tab.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Center, 'History'), findsOneWidget);
    // Header stays fixed after tab switch.
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
