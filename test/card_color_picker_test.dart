import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/widgets/card_form/card_color_picker.dart';
import 'package:cardminder/utils/page_transitions.dart';

void main() {
  group('CardColorPicker Widget Tests', () {
    testWidgets('renders SizedBox.shrink when isVisible is false without layout errors',
        (WidgetTester tester) async {
      int selectedColor = const Color(0xFF0F172A).toARGB32();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardColorPicker(
                customRgbColorValue: selectedColor,
                onColorChanged: (c) => selectedColor = c,
                isVisible: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_color_picker_hidden')), findsOneWidget);
      expect(find.text('Pick Your Color'), findsNothing);
    });

    testWidgets('renders full color picker when isVisible is true and allows selecting preset swatches',
        (WidgetTester tester) async {
      int selectedColor = const Color(0xFF0F172A).toARGB32();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardColorPicker(
                customRgbColorValue: selectedColor,
                onColorChanged: (c) => selectedColor = c,
                isVisible: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_color_picker_visible')), findsOneWidget);
      expect(find.text('Pick Your Color'), findsOneWidget);

      // Tap on a preset swatch
      final swatchFinder = find.byType(GestureDetector);
      expect(swatchFinder, findsWidgets);
      await tester.tap(swatchFinder.at(1));
      await tester.pumpAndSettle();
    });

    testWidgets('zero-width constraints do not crash CardColorPicker',
        (WidgetTester tester) async {
      int selectedColor = const Color(0xFF0F172A).toARGB32();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: CardColorPicker(
                customRgbColorValue: selectedColor,
                onColorChanged: (c) => selectedColor = c,
                isVisible: true,
              ),
            ),
          ),
        ),
      );

      // Should not throw performLayout or _SliderLayout assertions
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('pillRevealRoute Transition Tests', () {
    testWidgets('navigates with pillRevealRoute without throwing exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    pillRevealRoute(
                      const Scaffold(body: Text('Add Card Page')),
                      originRect: const Rect.fromLTWH(100, 500, 60, 30),
                      center: const Offset(130, 515),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      // Pump initial frame of transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);

      // Complete transition
      await tester.pumpAndSettle();
      expect(find.text('Add Card Page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
