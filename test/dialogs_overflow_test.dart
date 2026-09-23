import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/services/backup_service.dart';
import 'package:cardminder/theme/app_theme.dart';
import 'package:cardminder/widgets/delete_confirmation_dialog.dart';
import 'package:cardminder/widgets/home/edit_user_name_dialog.dart';
import 'package:cardminder/widgets/card_form/card_digits_dialog.dart';
import 'package:cardminder/widgets/backup_dialogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Typical mobile landscape sizes:
  // Compact landscape phone: 640x360 or 740x360 or 800x360
  // Constrained landscape height (with keyboard or on smaller devices): height = 320 or 280
  final landscapeSizes = [
    const Size(800, 360),
    const Size(640, 360),
    const Size(800, 320),
    const Size(700, 280),
  ];

  for (final size in landscapeSizes) {
    group('Dialog landscape overflow test on ${size.width}x${size.height}', () {
      testWidgets('DeleteConfirmationDialog does not overflow in landscape',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDeleteConfirmationDialog(
                    context: context,
                    cardName: 'Test Sapphire Reserve Card',
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Card'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EditUserNameDialog does not overflow in landscape',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => EditUserNameDialog.show(
                    context: context,
                    currentName: 'Test User',
                    onSave: (_) {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Your Name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('CardDigitsDialog does not overflow in landscape',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => CardDigitsDialog.show(context, '1234'),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Last 4 Digits'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SetBackupPinDialog does not overflow in landscape',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const SetBackupPinDialog(),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Set Backup PIN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('RestoreConfirmDialog does not overflow in landscape',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final backupData = BackupData(
          cards: [],
          settings: AppSettings(userName: 'Test User'),
          exportDate: DateTime(2026, 9, 5, 12, 0),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => RestoreConfirmDialog(backupData: backupData),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Restore Backup?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
