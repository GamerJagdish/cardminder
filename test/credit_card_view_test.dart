import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/widgets/animated_odometer.dart';
import 'package:cardminder/widgets/credit_card_view.dart';
import 'package:cardminder/theme/app_theme.dart';

void main() {
  group('CreditCardView & Animation Tests', () {
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

    testWidgets('renders CreditCardView with card data without error',
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

      expect(find.text('Sapphire Preferred'), findsOneWidget);
      expect(find.text('4321'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders CreditCardView with isFrosted true and BackdropFilter without error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreditCardView(
              card: testCard,
              isFrosted: true,
              frostedOpacity: 0.80,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Sapphire Preferred'), findsOneWidget);
      expect(find.text('4321'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AnimatedOdometerText rolls values smoothly without error',
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
      expect(tester.takeException(), isNull);
    });

    testWidgets('Flip3DText flips smoothly and swaps text at midpoint',
        (WidgetTester tester) async {
      String displayedText = 'CREDIT';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Flip3DText(
                      text: displayedText,
                      axis: FlipAxis.horizontal,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => displayedText = 'DEBIT'),
                      child: const Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('CREDIT'), findsOneWidget);
      expect(find.text('DEBIT'), findsNothing);

      // Trigger flip
      await tester.tap(find.text('Toggle'));
      await tester.pump(); // Start animation

      // Pump 80ms (before midpoint at 100ms): still showing CREDIT
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('CREDIT'), findsOneWidget);

      // Pump past midpoint (120ms total): now swapped to DEBIT
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('DEBIT'), findsOneWidget);

      // Settle animation
      await tester.pumpAndSettle();
      expect(find.text('DEBIT'), findsOneWidget);
      expect(find.text('CREDIT'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FlipCardNetworkLogo flips smoothly between networks',
        (WidgetTester tester) async {
      String currentNetwork = 'Visa';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    FlipCardNetworkLogo(network: currentNetwork),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => currentNetwork = 'Mastercard'),
                      child: const Text('Change'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flip-logo-Visa')), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('flip-logo-Mastercard')), findsOneWidget);
      expect(find.byKey(const ValueKey('flip-logo-Visa')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

