import 'dart:io';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/services/backup_service.dart';
import 'package:cardminder/theme/app_theme.dart';
import 'package:cardminder/widgets/backup_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backup Dialogs Landscape & Constrained Viewport Tests', () {
    testWidgets('SetBackupPinDialog renders without overflow and is scrollable',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SetBackupPinDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Backup PIN'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UnlockBackupPinDialog renders without overflow and is scrollable',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UnlockBackupPinDialog(
              file: File('dummy_backup.cardminder'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unlock Backup'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RestoreConfirmDialog renders without overflow and is scrollable',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 320);
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
          home: Scaffold(
            body: RestoreConfirmDialog(
              backupData: backupData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore Backup?'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
