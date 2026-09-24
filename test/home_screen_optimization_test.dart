import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/models/notification_log.dart';
import 'package:cardminder/providers/card_provider.dart';
import 'package:cardminder/providers/settings_provider.dart';
import 'package:cardminder/screens/home_screen.dart';
import 'package:cardminder/services/notification_log_service.dart';
import 'package:cardminder/theme/app_theme.dart';
import 'package:cardminder/utils/app_route_observer.dart';
import 'package:cardminder/utils/page_transitions.dart';
import 'package:cardminder/widgets/home/home_view.dart';
import 'package:cardminder/widgets/theme/shader_background_view.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings? _initialSettings;
  FakeSettingsNotifier([this._initialSettings]);

  @override
  AppSettings build() =>
      _initialSettings ?? AppSettings(animateBackground: true, themePreset: 'classic');

  @override
  Future<void> updateSettings(AppSettings newSettings, List<CreditCard> cards) async {
    state = newSettings;
  }
}

class FakeCardNotifier extends CardNotifier {
  @override
  CardState build() => CardState(
        cards: [
          CreditCard(
            id: 'test_card_1',
            cardName: 'Visa Signature',
            lastFourDigits: '1111',
            lastTransactionDate: DateTime.now().subtract(const Duration(days: 10)),
            colorIndex: 0,
            cardType: 'Credit Card',
            network: 'Visa',
          ),
          CreditCard(
            id: 'test_card_2',
            cardName: 'Mastercard World',
            lastFourDigits: '2222',
            lastTransactionDate: DateTime.now().subtract(const Duration(days: 5)),
            colorIndex: 1,
            cardType: 'Credit Card',
            network: 'Mastercard',
          ),
        ],
      );
}

class FakeNotificationLogNotifier extends NotificationLogNotifier {
  @override
  List<NotificationLog> build() => [];

  @override
  Future<void> markAllAsRead() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableScreen({AppSettings? settings}) {
    return ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(
          () => FakeSettingsNotifier(settings),
        ),
        cardNotifierProvider.overrideWith(FakeCardNotifier.new),
        notificationLogNotifierProvider.overrideWith(FakeNotificationLogNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        navigatorObservers: [appRouteObserver],
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen & HomeView Optimization Tests', () {
    testWidgets('Shader animates when on Home tab and pauses when switched to Settings tab',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Home tab is initially active (tab 0)
      final homeViewFinder = find.byType(HomeView);
      expect(homeViewFinder, findsOneWidget);
      final homeView = tester.widget<HomeView>(homeViewFinder);
      expect(homeView.isActive, isTrue);

      final shaderFinder = find.byType(ShaderBackgroundView);
      expect(shaderFinder, findsOneWidget);
      var shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Switch to Settings tab (tab 1)
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // HomeView is now offstage in IndexedStack with isActive: false
      final offstageHomeFinder = find.byType(HomeView, skipOffstage: false);
      final updatedHomeView = tester.widget<HomeView>(offstageHomeFinder);
      expect(updatedHomeView.isActive, isFalse);

      // ShaderBackgroundView on offstage HomeView has animate set to false to save GPU/CPU cycles
      final offstageShaderFinder =
          find.byType(ShaderBackgroundView, skipOffstage: false);
      shaderWidget = tester.widget<ShaderBackgroundView>(offstageShaderFinder);
      expect(shaderWidget.animate, isFalse);

      // Switch back to Home tab (tab 0)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();

      final restoredHomeView = tester.widget<HomeView>(homeViewFinder);
      expect(restoredHomeView.isActive, isTrue);
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);
    });

    testWidgets('Shader pauses when a child screen is pushed and resumes when popped',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final shaderFinder =
          find.byType(ShaderBackgroundView, skipOffstage: false);
      expect(shaderFinder, findsOneWidget);
      var shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Push a child route on top of HomeScreen with slideUpRoute
      final navigator =
          Navigator.of(tester.element(find.byType(Scaffold).first));
      navigator.push(
        slideUpRoute(
          const Scaffold(body: Text('Child Screen')),
        ),
      );

      // During the push transition (secondaryAnimation starts forward)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isFalse);

      // Let the push transition settle completely
      await tester.pumpAndSettle();
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isFalse);

      // Pop the child screen back to HomeScreen
      navigator.pop();

      // During the pop transition (secondaryAnimation runs in reverse)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isFalse);

      // After the pop transition completely settles
      await tester.pumpAndSettle();
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      // Shader smoothly resumes!
      expect(shaderWidget.animate, isTrue);
    });

    testWidgets(
        'Shader continues running seamlessly during carousel swiping and scrolling',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final shaderFinder = find.byType(ShaderBackgroundView);
      var shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Simulate an active horizontal drag gesture on the credit card carousel
      final cardFinder = find.text('Visa Signature').first;
      expect(cardFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(cardFinder));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      // While actively dragging/swiping cards, background shader continues running seamlessly
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // End the drag and let it settle
      await gesture.up();
      await tester.pumpAndSettle();

      // After settling, shader continues running smoothly
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);
    });

    testWidgets(
        'Shader continues running when EditUserNameDialog is opened and Scaffold does not resize for keyboard',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final shaderFinder = find.byType(ShaderBackgroundView);
      var shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Verify HomeScreen scaffold has resizeToAvoidBottomInset set to false
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.resizeToAvoidBottomInset, isFalse);

      // Tap the user greeting header to open EditUserNameDialog
      final greetingFinder = find.text('Welcome back,');
      expect(greetingFinder, findsOneWidget);
      await tester.tap(greetingFinder);
      await tester.pumpAndSettle();

      // Dialog is now open on top of HomeScreen
      expect(find.text('Edit Your Name'), findsOneWidget);

      // Shader continues running smoothly in the background while dialog is active
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Your Name'), findsNothing);
      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);
    });

    testWidgets('ShaderBackgroundView stops when app lifecycle state is paused and resumes when resumed',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final shaderFinder = find.byType(ShaderBackgroundView);
      var shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);

      // Simulate app going into background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Simulate app resuming
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      shaderWidget = tester.widget<ShaderBackgroundView>(shaderFinder);
      expect(shaderWidget.animate, isTrue);
    });
  });
}
