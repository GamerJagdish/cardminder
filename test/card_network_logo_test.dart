import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/widgets/credit_card/card_network_logo.dart';
import 'package:cardminder/widgets/credit_card_view.dart';
import 'package:cardminder/theme/app_theme.dart';

void main() {
  group('CardNetworkLogo Visa Tests', () {
    testWidgets('renders visa.svg with explicitly provided color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'Visa',
              color: Colors.white,
            ),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final SvgPicture svgWidget = tester.widget(svgFinder);
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );
    });

    testWidgets('adapts visa.svg color based on light vs dark backgroundColor',
        (WidgetTester tester) async {
      // Light background
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'Visa',
              backgroundColor: Colors.white,
            ),
          ),
        ),
      );

      final lightSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        lightSvg.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );

      // Dark background
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'Visa',
              backgroundColor: Colors.black,
            ),
          ),
        ),
      );

      final darkSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        darkSvg.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );
    });

    testWidgets('adapts visa.svg color based on theme brightness when no color/bg given',
        (WidgetTester tester) async {
      // Light Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'Visa'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightThemeSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        lightThemeSvg.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );

      // Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'Visa'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkThemeSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        darkThemeSvg.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );
    });

    testWidgets('CreditCardView dynamically colors visa.svg according to card background',
        (WidgetTester tester) async {
      // Dark card (Navy)
      final darkCard = CreditCard(
        id: 'dark-visa',
        cardName: 'Dark Visa',
        network: 'Visa',
        colorIndex: 0, // Navy gradient, dark
        lastTransactionDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CreditCardView(card: darkCard),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkCardSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        darkCardSvg.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );

      // Light card (White/Light Yellow custom color)
      final lightCard = CreditCard(
        id: 'light-visa',
        cardName: 'Light Visa',
        network: 'Visa',
        colorIndex: 0xFFFFFBEB, // Amber 50, light
        lastTransactionDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CreditCardView(card: lightCard),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightCardSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        lightCardSvg.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );
    });

    testWidgets('renders mastercard.svg with intrinsic colors and without colorFilter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(network: 'Mastercard'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final SvgPicture svgWidget = tester.widget(svgFinder);
      expect(svgWidget.colorFilter, isNull);
    });
  });
}
