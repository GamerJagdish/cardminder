import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/models/credit_card.dart';
import 'package:cardminder/models/notification_log.dart';
import 'package:cardminder/providers/card_provider.dart';
import 'package:cardminder/providers/settings_provider.dart';
import 'package:cardminder/screens/settings/theme_preview_screen.dart';
import 'package:cardminder/services/notification_log_service.dart';
import 'package:cardminder/theme/app_theme.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings? _initialSettings;
  FakeSettingsNotifier([this._initialSettings]);

  @override
  AppSettings build() => _initialSettings ?? AppSettings(animateBackground: false);

  @override
  Future<void> updateSettings(AppSettings newSettings, List<CreditCard> cards) async {
    state = newSettings;
  }
}

class FakeCardNotifier extends CardNotifier {
  @override
  CardState build() => CardState(cards: []);
}

class FakeNotificationLogNotifier extends NotificationLogNotifier {
  @override
  List<NotificationLog> build() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableScreen({ThemeData? theme, AppSettings? initialSettings}) {
    return ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(() => FakeSettingsNotifier(initialSettings)),
        cardNotifierProvider.overrideWith(FakeCardNotifier.new),
        notificationLogNotifierProvider.overrideWith(FakeNotificationLogNotifier.new),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: const ThemePreviewScreen(),
      ),
    );
  }

  group('ThemePreviewScreen Theme Picker Sheet Tests', () {
    testWidgets('Tapping Theme button opens the revamped Theme Presets sheet',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Find the Theme button in bottom bar
      expect(find.text('Theme'), findsOneWidget);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Verify the new Theme Presets sheet is visible
      expect(find.text('Theme Presets'), findsOneWidget);
      expect(find.byIcon(Icons.palette_rounded), findsWidgets);
      final closeIconFinder = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeIconFinder, findsOneWidget);
      final closeContainer = tester.widget<Container>(
        find.ancestor(of: closeIconFinder, matching: find.byType(Container)).first,
      );
      final closeDec = closeContainer.decoration as BoxDecoration?;
      expect(closeDec?.shape, BoxShape.circle);

      // Verify theme presets are rendered as visual cards in the sheet
      final sheetFinder = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheetFinder, matching: find.text('Classic CardMinder')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('Waveform')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheetFinder, matching: find.text('Balatro')),
        findsOneWidget,
      );
    });

    testWidgets(
        'Tapping a theme with variants shows variants in popup with back button and selecting a variant closes sheet',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Presets'), findsOneWidget);

      // Tap on 'Waveform' (has variants) inside bottom sheet
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Waveform')),
      );
      await tester.pumpAndSettle();

      // Should show 'Waveform Styles' header and back button in popup
      expect(find.text('Waveform Styles'), findsOneWidget);
      final backIconFinder = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.arrow_back_rounded),
      );
      expect(backIconFinder, findsOneWidget);
      final backContainer = tester.widget<Container>(
        find.ancestor(of: backIconFinder, matching: find.byType(Container)).first,
      );
      final backDec = backContainer.decoration as BoxDecoration?;
      expect(backDec?.shape, BoxShape.circle);

      // Variants should be visible inside the popup
      expect(find.text('Ruby Waveform'), findsOneWidget);
      expect(find.text('Gold Waveform'), findsOneWidget);

      // Tap Back button in popup to return to main themes
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.byIcon(Icons.arrow_back_rounded)),
      );
      await tester.pumpAndSettle();

      // Should return to main themes
      expect(find.text('Theme Presets'), findsOneWidget);
      expect(find.text('Waveform Styles'), findsNothing);

      // Tap 'Waveform' again, then tap a variant to select and close
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Waveform')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waveform Styles'), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Ruby Waveform')),
      );
      await tester.pumpAndSettle();

      // Bottom sheet should now be closed
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('Tapping a theme preset without variants selects it and closes the sheet',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        initialSettings: AppSettings(
          themePreset: 'silly_strings',
          animateBackground: false,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Presets'), findsOneWidget);

      // Tap on 'Classic CardMinder' (standalone theme without variants)
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Classic CardMinder')),
      );
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed immediately
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('Theme Presets sheet renders in landscape without layout errors or overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Presets'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Classic CardMinder')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Theme Presets sheet renders in constrained landscape 800x320 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(800, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Theme Presets'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Close the sheet via X icon in bottom sheet
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Theme Presets'), findsNothing);
    });
  });

  group('ThemePreviewScreen Creative Landscape Layout Tests', () {
    testWidgets(
        'Displays landscape layout with close button on left and control card on right',
        (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Left column: close button without vertical text
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('t\nh\ne\nm\ne\n\np\nr\ne\nv\ni\ne\nw'), findsNothing);

      // Right column: THEME PREVIEW eyebrow, theme name, description, animation toggle, and action buttons
      expect(find.text('THEME PREVIEW'), findsOneWidget);
      expect(find.text('Classic CardMinder'), findsOneWidget);
      expect(find.text('The original clean minimalist look'), findsOneWidget);
      expect(find.text('Animation Off'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Animation toggle in landscape right panel updates state',
        (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(find.text('Animation Off'), findsOneWidget);

      await tester.tap(find.text('Animation Off'));
      await tester.pump();

      expect(find.text('Animation On'), findsOneWidget);
    });

    testWidgets('Renders in ultra-compact 700x280 landscape without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(700, 280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(find.text('THEME PREVIEW'), findsOneWidget);
      expect(find.text('Classic CardMinder'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ThemePreviewScreen Optimization Tests', () {
    testWidgets('Mode toggle switches between Dark and Light only, removing System cycle',
        (tester) async {
      // Start with system default in light theme
      await tester.pumpWidget(buildTestableScreen(
        initialSettings: AppSettings(themeMode: 'system'),
        theme: AppTheme.lightTheme,
      ));
      await tester.pumpAndSettle();

      // Initially shows System
      expect(find.text('System'), findsOneWidget);

      // First tap: switches to Dark (since current brightness is light)
      await tester.tap(find.text('Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsNothing);

      // Second tap: switches to Light
      await tester.tap(find.text('Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System'), findsNothing);

      // Third tap: switches back to Dark (never returns to System)
      await tester.tap(find.text('Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsNothing);
    });

    testWidgets('Silly Noir Animation On button uses high-contrast dark color in light mode',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        initialSettings: AppSettings(
          themePreset: 'silly_strings',
          animateBackground: true,
        ),
        theme: AppTheme.lightTheme, // light mode
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the Animation On text
      final animOnFinder = find.text('Animation On');
      expect(animOnFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(animOnFinder);
      // High-contrast color for monochrome/light line colors on light surfaces
      expect(textWidget.style?.color, const Color(0xFF0F172A));

      // Find the icon and verify its color is also high-contrast dark
      final iconFinder = find.byIcon(Icons.motion_photos_on_rounded);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, const Color(0xFF0F172A));
    });

    testWidgets('Tapping Close button invokes close handler without exception',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final closeButtonFinder = find.byIcon(Icons.close_rounded);
      expect(closeButtonFinder, findsOneWidget);

      await tester.tap(closeButtonFinder);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Selecting a theme variant from popup animates carousel and settles on target preset',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen(
        initialSettings: AppSettings(animateBackground: false),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Open Waveform in popup
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Waveform')),
      );
      await tester.pumpAndSettle();

      // Select Ruby Waveform
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Ruby Waveform')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bottom sheet is closed and target preset is active
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Ruby Waveform'), findsWidgets);
    });
  });
}
