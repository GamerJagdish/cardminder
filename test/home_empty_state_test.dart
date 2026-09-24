import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/models/notification_log.dart';
import 'package:cardminder/providers/card_provider.dart';
import 'package:cardminder/providers/settings_provider.dart';
import 'package:cardminder/screens/add_edit_card_screen.dart';
import 'package:cardminder/screens/home_screen.dart';
import 'package:cardminder/services/notification_log_service.dart';
import 'package:cardminder/theme/app_theme.dart';
import 'package:cardminder/utils/app_route_observer.dart';
import 'package:cardminder/widgets/home/home_empty_state.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => AppSettings(animateBackground: false);

  @override
  Future<void> updateSettings(AppSettings newSettings, List<CreditCard> cards) async {
    state = newSettings;
  }
}

class FakeEmptyCardNotifier extends CardNotifier {
  @override
  CardState build() => CardState(cards: []);
}

class FakeNotificationLogNotifier extends NotificationLogNotifier {
  @override
  List<NotificationLog> build() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableEmptyHomeScreen({ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(FakeSettingsNotifier.new),
        cardNotifierProvider.overrideWith(FakeEmptyCardNotifier.new),
        notificationLogNotifierProvider.overrideWith(FakeNotificationLogNotifier.new),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        navigatorObservers: [appRouteObserver],
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeEmptyState Frosted Card & Pill Buttons Tests', () {
    testWidgets('Renders frosted logo, high-visibility description, and rounded pill buttons with frost effect',
        (tester) async {
      await tester.pumpWidget(buildTestableEmptyHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsOneWidget);

      // 1. Frosted logo orb
      expect(find.byIcon(Icons.credit_card_off_outlined), findsOneWidget);

      // 2. Title
      expect(find.text('No Cards Tracked Yet'), findsOneWidget);

      // 3. High-visibility description text
      final descFinder = find.text(
        'Never let a credit card deactivate again. Add your first card or restore an encrypted backup to start tracking.',
      );
      expect(descFinder, findsOneWidget);
      final descText = tester.widget<Text>(descFinder);
      expect(descText.style?.fontSize, 14.5);
      expect(descText.style?.fontWeight, FontWeight.w500);

      // 4. Button 1: Add First Card
      final addBtnFinder = find.widgetWithText(ElevatedButton, 'Add First Card');
      expect(addBtnFinder, findsOneWidget);
      final addBtn = tester.widget<ElevatedButton>(addBtnFinder);
      expect(addBtn.child, isA<Text>());
      final addBtnShape = addBtn.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(addBtnShape?.borderRadius, BorderRadius.circular(27));

      // 5. Button 2: Restore from Backup
      final restoreBtnFinder = find.widgetWithText(ElevatedButton, 'Restore from Backup');
      expect(restoreBtnFinder, findsOneWidget);
      final restoreBtn = tester.widget<ElevatedButton>(restoreBtnFinder);
      expect(restoreBtn.child, isA<Text>());
      final restoreBtnShape = restoreBtn.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(restoreBtnShape?.borderRadius, BorderRadius.circular(27));

      // Verify text size 16 and bold
      final addBtnText = addBtn.child as Text;
      expect(addBtnText.style?.fontSize, 16);
      expect(addBtnText.style?.fontWeight, FontWeight.bold);

      final restoreBtnText = restoreBtn.child as Text;
      expect(restoreBtnText.style?.fontSize, 16);
      expect(restoreBtnText.style?.fontWeight, FontWeight.bold);

      // Verify BackdropFilter exists inside HomeEmptyState for card, top logo, and both buttons
      final backdropFilters = find.descendant(
        of: find.byType(HomeEmptyState),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFilters, findsNWidgets(4)); // Container card + top logo + button 1 + button 2
    });

    testWidgets('Tapping Add First Card opens AddEditCardScreen',
        (tester) async {
      await tester.pumpWidget(buildTestableEmptyHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add First Card'));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditCardScreen), findsOneWidget);
      expect(find.text('Add New Card'), findsOneWidget);

      Navigator.of(tester.element(find.byType(AddEditCardScreen))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(HomeEmptyState), findsOneWidget);
    });

    final landscapeSizes = [
      const Size(800, 360),
      const Size(640, 360),
      const Size(800, 320),
      const Size(700, 280),
    ];

    for (final size in landscapeSizes) {
      testWidgets('HomeEmptyState renders without overflow in landscape on ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableEmptyHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(HomeEmptyState), findsOneWidget);
        expect(find.text('No Cards Tracked Yet'), findsOneWidget);
        expect(find.text('Add First Card'), findsOneWidget);
        expect(find.text('Restore from Backup'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
