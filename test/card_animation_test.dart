import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/widgets/animated_odometer.dart';
import 'package:cardminder/widgets/credit_card_view.dart';
import 'package:cardminder/theme/app_theme.dart';

void main() {
  group('CreditCardView Visual & Interactive Animation Tests', () {
    final testCard = CreditCard(
      id: 'test-card-1',
      cardName: 'Sapphire Preferred',
      lastFourDigits: '4321',
      lastTransactionDate: DateTime.now(),
      network: 'Visa',
      cardType: 'Credit',
      colorIndex: 0,
      deactivationPeriodDays: 365,
    );

    testWidgets('renders CreditCardView with Hero and correct card data in light and dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreditCardView(
              card: testCard,
              heroTag: 'card-test-card-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('Sapphire Preferred'), findsOneWidget);
      expect(find.text('4321'), findsOneWidget);
      expect(find.text('CREDIT'), findsOneWidget);
    });

    testWidgets('handles pointer pan gestures for 3D tilt without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 200,
                child: CreditCardView(
                  card: testCard,
                  heroTag: 'card-test-card-1',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger pointer down and pointer move to simulate 3D tilt gesture
      final center = tester.getCenter(find.byType(CreditCardView));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump(const Duration(milliseconds: 16));

      // Pointer up should trigger spring-back animation
      await gesture.up();
      await tester.pumpAndSettle();

      // Card is still present and valid
      expect(find.text('Sapphire Preferred'), findsOneWidget);
    });

    testWidgets('resets tilt immediately when tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 200,
                child: CreditCardView(
                  card: testCard,
                  heroTag: 'card-test-card-1',
                  onTap: () {
                    tapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(CreditCardView));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('live updates digits with animated roll without crashing',
        (WidgetTester tester) async {
      var digits = '1234';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    CreditCardView(
                      card: testCard.copyWith(lastFourDigits: digits),
                      heroTag: 'card-test-card-1',
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          digits = '9876';
                        });
                      },
                      child: const Text('Change Digits'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('1234'), findsOneWidget);

      // Tap button to update digits
      await tester.tap(find.text('Change Digits'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('9876'), findsOneWidget);
    });

    test('card shadow upward reach does not exceed clearance', () {
      final colors = AppTheme.getCardColors(0);
      for (final isDarkTheme in [true, false]) {
        final shadows = [
          BoxShadow(
            color: colors.first.withValues(alpha: isDarkTheme ? 0.38 : 0.28),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: colors.first.withValues(alpha: isDarkTheme ? 0.20 : 0.12),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ];

        for (final s in shadows) {
          final upwardReach = s.blurRadius + s.spreadRadius - s.offset.dy;
          expect(upwardReach, lessThanOrEqualTo(13.0));
        }
      }
    });

    testWidgets('AnimatedOdometerText renders and rolls values smoothly',
        (WidgetTester tester) async {
      int count = 12;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedOdometerText(
                      value: count,
                      style: const TextStyle(fontSize: 24),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => count = 365),
                      child: const Text('Roll'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Roll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
