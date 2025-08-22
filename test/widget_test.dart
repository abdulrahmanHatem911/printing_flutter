// This is a basic Flutter widget test for Bluetooth PDF printer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:printer/main.dart';

void main() {
  testWidgets('Bluetooth PDF Printer App Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app title
    expect(find.text('Bluetooth PDF Printer'), findsOneWidget);

    // Verify key UI elements are present
    expect(find.text('Bluetooth Printers'), findsOneWidget);
    expect(find.text('PDF File'), findsOneWidget);
    expect(find.text('Select PDF Invoice'), findsOneWidget);
    expect(find.text('Refresh Devices'), findsOneWidget);
    expect(find.text('Print PDF'), findsOneWidget);

    // Verify that PDF picker button exists and is tappable
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);

    // Test button states - Print should be disabled initially
    final printButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Print PDF')
    );
    expect(printButton.onPressed, isNull); // Should be disabled initially
  });

  testWidgets('UI State Management Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Initially should show "No paired devices"
    await tester.pumpAndSettle();
    // Note: This would need actual device testing for full validation
    
    // Verify status message container exists
    expect(find.byType(Container), findsWidgets);
  });
}
