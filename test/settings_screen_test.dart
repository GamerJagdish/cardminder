import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/providers/card_provider.dart';
import 'package:cardminder/providers/settings_provider.dart';
import 'package:cardminder/screens/settings_screen.dart';
import 'package:cardminder/screens/settings/sections/backup_settings_section.dart';
import 'package:cardminder/screens/settings/widgets/settings_tiles.dart';
import 'package:cardminder/theme/app_theme.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => AppSettings(animateBackground: false);
}

class FakeCardNotifier extends CardNotifier {
  @override
  CardState build() => CardState(cards: [], isLoading: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Screen Rounded Buttons Tests', () {
    testWidgets(
        'Sync Widget & Notifications button uses rounded pill shape (radius 26)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsNotifierProvider.overrideWith(FakeSettingsNotifier.new),
            cardNotifierProvider.overrideWith(FakeCardNotifier.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final syncBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Sync Widget & Notifications'),
      );
      final shape =
          syncBtn.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, BorderRadius.circular(26));
    });

    testWidgets(
        'BackupSettingsSection Create and Restore buttons use rounded pill shape (radius 22)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BackupSettingsSection(
                settings: AppSettings(),
                onUpdateSettings: (_) {},
                onChangeBackupLocation: () {},
                onCreateBackup: () {},
                onRestoreBackup: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final createBackupContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Create Backup'),
              matching: find.byType(Container),
            )
            .first,
      );
      final createDec = createBackupContainer.decoration as BoxDecoration?;
      expect(createDec?.borderRadius, BorderRadius.circular(22));

      final restoreBackupContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Restore Backup'),
              matching: find.byType(Container),
            )
            .first,
      );
      final restoreDec = restoreBackupContainer.decoration as BoxDecoration?;
      expect(restoreDec?.borderRadius, BorderRadius.circular(22));
    });

    testWidgets('PillOption buttons use rounded pill shape (radius 20)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                PillOption(
                  label: 'All Cards',
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pillContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('All Cards'),
              matching: find.byType(Container),
            )
            .first,
      );
      final dec = pillContainer.decoration as BoxDecoration?;
      expect(dec?.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('DebugActionButton uses rounded pill shape (radius 22)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DebugActionButton(
              icon: Icons.check,
              label: 'Test Action',
              busy: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final debugBtn = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Test Action'),
      );
      final shape =
          debugBtn.style?.shape?.resolve({}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, BorderRadius.circular(22));
    });
  });
}
