import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/widgets/credit_card_view.dart';
import 'package:cardminder/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardNetworkLogo Rendering', () {
    testWidgets('renders all supported networks without errors',
        (WidgetTester tester) async {
      for (final net in ['Visa', 'Mastercard', 'RuPay', 'Amex', 'Discover']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CardNetworkLogo(network: net),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CardNetworkLogo), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('respects custom height when explicitly provided',
        (WidgetTester tester) async {
      const double customHeight = 24.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardNetworkLogo(network: 'Visa', height: customHeight),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(CardNetworkLogo));
      expect(size.height, equals(customHeight));
    });
  });

  group('Visa Dynamic Contrast Coloring Tests', () {
    testWidgets('applies explicitly provided color override',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'Visa',
              color: Colors.red,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SvgPicture svgWidget = tester.widget(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Colors.red, BlendMode.srcIn)),
      );
    });

    testWidgets('adapts to light background with dark slate color',
        (WidgetTester tester) async {
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
      await tester.pumpAndSettle();

      final SvgPicture svgWidget = tester.widget(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );
    });

    testWidgets('adapts to dark background with white color',
        (WidgetTester tester) async {
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
      await tester.pumpAndSettle();

      final SvgPicture svgWidget = tester.widget(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );
    });

    testWidgets('defaults to dark color in Light Theme when unconfigured',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'Visa'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SvgPicture svgWidget = tester.widget(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );
    });

    testWidgets('defaults to white color in Dark Theme when unconfigured',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'Visa'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final SvgPicture svgWidget = tester.widget(find.byType(SvgPicture));
      expect(
        svgWidget.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );
    });
  });

  group('RuPay Dynamic Brand Logo Switching Tests', () {
    testWidgets('adapts to light background with Rupay-Blue.png',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'RuPay',
              backgroundColor: Colors.white,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect((imageWidget.image as AssetImage).assetName,
          equals('assets/logos/Rupay-Blue.png'));
    });

    testWidgets('adapts to dark background with RuPay-White.png',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardNetworkLogo(
              network: 'RuPay',
              backgroundColor: Colors.black,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect((imageWidget.image as AssetImage).assetName,
          equals('assets/logos/RuPay-White.png'));
    });

    testWidgets('defaults to blue logo in Light Theme and white logo in Dark Theme',
        (WidgetTester tester) async {
      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'RuPay'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Image imageWidget = tester.widget(find.byType(Image));
      expect((imageWidget.image as AssetImage).assetName,
          equals('assets/logos/Rupay-Blue.png'));

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CardNetworkLogo(network: 'RuPay'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      imageWidget = tester.widget(find.byType(Image));
      expect((imageWidget.image as AssetImage).assetName,
          equals('assets/logos/RuPay-White.png'));
    });
  });

  group('CreditCardView Network Integration Tests', () {
    testWidgets('dynamically colors Visa logo according to card background',
        (WidgetTester tester) async {
      // Dark card (Navy)
      final darkCard = CreditCard(
        id: 'dark-visa',
        cardName: 'Dark Visa',
        network: 'Visa',
        colorIndex: 0,
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

      final darkSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        darkSvg.colorFilter,
        equals(const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      );

      // Light card (Amber 50, light background)
      final lightCard = CreditCard(
        id: 'light-visa',
        cardName: 'Light Visa',
        network: 'Visa',
        colorIndex: 0xFFFFFBEB,
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

      final lightSvg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        lightSvg.colorFilter,
        equals(const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn)),
      );
    });

    testWidgets('dynamically switches RuPay logo according to card background',
        (WidgetTester tester) async {
      // Dark card (Navy)
      final darkCard = CreditCard(
        id: 'dark-rupay',
        cardName: 'Dark RuPay',
        network: 'RuPay',
        colorIndex: 0,
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

      final darkImage = tester.widget<Image>(find.byType(Image));
      expect(
        (darkImage.image as AssetImage).assetName,
        equals('assets/logos/RuPay-White.png'),
      );

      // Light card (Amber 50, light background)
      final lightCard = CreditCard(
        id: 'light-rupay',
        cardName: 'Light RuPay',
        network: 'RuPay',
        colorIndex: 0xFFFFFBEB,
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

      final lightImage = tester.widget<Image>(find.byType(Image));
      expect(
        (lightImage.image as AssetImage).assetName,
        equals('assets/logos/Rupay-Blue.png'),
      );
    });

    testWidgets(
        'renders interactive network dropdown badge with minHeight 40 and opens menu',
        (WidgetTester tester) async {
      String? selectedNet;
      final card = CreditCard(
        id: 'test-card',
        cardName: 'My Card',
        network: 'Visa',
        colorIndex: 0,
        lastTransactionDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CreditCardView(
              card: card,
              onNetworkSelected: (net) => selectedNet = net,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the dropdown button
      final dropdownFinder = find.byType(PopupMenuButton<String>);
      expect(dropdownFinder, findsOneWidget);

      final badgeSize = tester.getSize(dropdownFinder);
      expect(badgeSize.height, greaterThanOrEqualTo(40.0),
          reason:
              'Dropdown badge should have at least 40px height for unified touch target');

      // Tap to open popup menu
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Verify all networks appear in popup menu items
      for (final net in ['Visa', 'Mastercard', 'RuPay', 'Amex', 'Discover']) {
        expect(find.text(net), findsOneWidget);
      }

      // Tap Mastercard
      await tester.tap(find.text('Mastercard'));
      await tester.pumpAndSettle();

      expect(selectedNet, equals('Mastercard'));
    });
  });
}
