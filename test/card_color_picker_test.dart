import 'package:material_ui/material_ui.dart';
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

    testWidgets('allows editing hex color badge directly and updates color',
        (WidgetTester tester) async {
      int selectedColor = const Color(0xFF0F172A).toARGB32();

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SingleChildScrollView(
                  child: CardColorPicker(
                    customRgbColorValue: selectedColor,
                    onColorChanged: (c) => setState(() => selectedColor = c),
                    isVisible: true,
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hexFieldFinder = find.byKey(const ValueKey('hex_color_input'));
      expect(hexFieldFinder, findsOneWidget);
      expect(tester.widget<TextField>(hexFieldFinder).controller?.text, '#0F172A');

      // Enter 6-digit hex (lowercase without #) -> formats to #FF5733 and updates color
      await tester.enterText(hexFieldFinder, 'ff5733');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(hexFieldFinder).controller?.text, '#FF5733');
      expect(selectedColor, const Color(0xFFFF5733).toARGB32());

      // Enter 3-digit shorthand hex and submit -> expands to #00AAFF
      await tester.enterText(hexFieldFinder, '#0af');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(hexFieldFinder).controller?.text, '#00AAFF');
      expect(selectedColor, const Color(0xFF00AAFF).toARGB32());

      // Enter incomplete hex (2 chars) and unfocus -> restores #00AAFF
      await tester.enterText(hexFieldFinder, '12');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(hexFieldFinder).controller?.text, '#00AAFF');
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
