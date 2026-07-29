import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme renders light theme correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Text('CardMinder Test'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('CardMinder Test'), findsOneWidget);
  });
}
