import 'dart:io';
import 'package:cardminder/models/app_settings.dart';
import 'package:cardminder/services/backup_service.dart';
import 'package:cardminder/services/update_service.dart';
import 'package:cardminder/theme/app_theme.dart';
import 'package:cardminder/widgets/backup_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppReleaseInfo', () {
    test('formattedDate formats DateTime correctly', () {
      final release = AppReleaseInfo(
        version: '1.2.5',
        apkUrl: 'https://example.com/cardminder.apk',
        releaseNotes: 'Some notes',
        apkFileName: 'cardminder-v1.2.5.apk',
        apkSizeBytes: 27892121,
        publishedAt: DateTime(2026, 9, 5, 14, 30),
      );

      expect(release.formattedDate, 'Sep 5, 2026');
      expect(release.formattedSize, '26.6 MB');
    });

    test('formattedDate returns empty string when publishedAt is null', () {
      final release = AppReleaseInfo(
        version: '1.2.5',
        apkUrl: 'https://example.com/cardminder.apk',
        releaseNotes: 'Some notes',
        apkFileName: 'cardminder-v1.2.5.apk',
        apkSizeBytes: 10485760,
        publishedAt: null,
      );

      expect(release.formattedDate, '');
      expect(release.formattedSize, '10.0 MB');
    });

    test('architecture and displayTitle extract correctly from apkFileName', () {
      final releaseX86 = AppReleaseInfo(
        version: '1.2.5',
        apkUrl: 'https://example.com/cardminder.apk',
        releaseNotes: 'Notes',
        apkFileName: 'CardMinder-1.2.5-x86_64.apk',
        apkSizeBytes: 27892121,
      );
      expect(releaseX86.architecture, 'x86_64');
      expect(releaseX86.displayTitle, 'CardMinder 1.2.5 (x86_64)');

      final releaseArm = AppReleaseInfo(
        version: 'v1.2.5',
        apkUrl: 'https://example.com/cardminder.apk',
        releaseNotes: 'Notes',
        apkFileName: 'CardMinder-1.2.5-arm64-v8a.apk',
        apkSizeBytes: 27892121,
      );
      expect(releaseArm.architecture, 'arm64-v8a');
      expect(releaseArm.displayTitle, 'CardMinder 1.2.5 (arm64-v8a)');

      final releaseGeneric = AppReleaseInfo(
        version: '1.2.5',
        apkUrl: 'https://example.com/cardminder.apk',
        releaseNotes: 'Notes',
        apkFileName: 'cardminder-v1.2.5.apk',
        apkSizeBytes: 27892121,
      );
      expect(releaseGeneric.architecture, '');
      expect(releaseGeneric.displayTitle, 'CardMinder 1.2.5');
    });
  });

  group('UpdateScreen Widget', () {
    final release = AppReleaseInfo(
      version: '1.2.5',
      apkUrl: 'https://example.com/cardminder.apk',
      releaseNotes: "## What's Changed\n* feat: shiny new feature",
      apkFileName: 'CardMinder-1.2.5-x86_64.apk',
      apkSizeBytes: 27892121,
      publishedAt: DateTime(2026, 9, 5),
    );

    tearDown(() {
      UpdateDownloadManager.instance.isDownloading = false;
      UpdateDownloadManager.instance.progress = 0.0;
      UpdateDownloadManager.instance.statusText = '';
      UpdateDownloadManager.instance.downloadedApkPath = null;
    });

    testWidgets('renders initial UpdateScreen dialog with Download and Close buttons',
        (WidgetTester tester) async {
      final updater = GithubReleaseApkUpdater();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UpdateScreen(
              release: release,
              updater: updater,
              currentVersion: '1.2.4',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & app name
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('CardMinder 1.2.5 (x86_64)'), findsOneWidget);

      // Verify date and size badges
      expect(find.text('26.6 MB'), findsOneWidget);
      expect(find.text('Sep 5, 2026'), findsOneWidget);

      // Verify What's New section (no star/sparkle icon)
      expect(find.text("WHAT'S NEW"), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

      // Verify primary download button says "Download" (no icon, no size in text)
      expect(find.text('Download'), findsOneWidget);

      // Verify full-width Close button exists underneath
      expect(find.text('Close'), findsOneWidget);

      // Verify header close icon is removed
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('displays morphing progress button when downloading and cancels on X tap',
        (WidgetTester tester) async {
      final updater = GithubReleaseApkUpdater();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UpdateScreen(
              release: release,
              updater: updater,
              currentVersion: '1.2.4',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate download in progress
      UpdateDownloadManager.instance.isDownloading = true;
      UpdateDownloadManager.instance.progress = 0.52;
      UpdateDownloadManager.instance.statusText = '52% (13.8 / 26.6 MB)';
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      UpdateDownloadManager.instance.notifyListeners();

      await tester.pumpAndSettle();

      // Progress button is visible
      expect(find.byKey(const ValueKey('morphing_progress_btn')), findsOneWidget);
      expect(find.text('Downloading...'), findsOneWidget);
      expect(find.text('52%'), findsOneWidget);
      expect(find.text('13.8 / 26.6 MB'), findsOneWidget);

      // Circular progress indicator and background text are removed
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Dismissing will continue downloading in background'),
        findsNothing,
      );

      // Tap inline 'X' cancel button inside progress button
      final cancelBtn = find.byTooltip('Cancel download');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Download is cancelled and button smoothly reverts to initial "Download" button
      expect(UpdateDownloadManager.instance.isDownloading, isFalse);
      expect(find.byKey(const ValueKey('initial_download_btn')), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('displays install button when download is completed',
        (WidgetTester tester) async {
      final updater = GithubReleaseApkUpdater();

      // Simulate download complete
      UpdateDownloadManager.instance.isDownloading = false;
      UpdateDownloadManager.instance.progress = 1.0;
      UpdateDownloadManager.instance.downloadedApkPath = '/dummy/cardminder-v1.2.5.apk';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UpdateScreen(
              release: release,
              updater: updater,
              currentVersion: '1.2.4',
            ),
          ),
        ),
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      UpdateDownloadManager.instance.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('install_action_btn')), findsOneWidget);
      expect(find.text('Update downloaded and verified'), findsOneWidget);
      expect(find.text('Install Update'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('UpdateScreen dynamically widens dialog in landscape orientation',
        (WidgetTester tester) async {
      final updater = GithubReleaseApkUpdater();
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: UpdateScreen(
              release: release,
              updater: updater,
              currentVersion: '1.2.4',
            ),
          ),
        ),
      );
      await tester.pump();

      // On 800px landscape, width is (800 * 0.85) = 680.0
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(ConstrainedBox),
        ),
      );
      final dialogBox = constrainedBoxes.firstWhere(
        (box) => box.constraints.minWidth == 680.0,
      );
      expect(dialogBox.constraints.maxWidth, 680.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('ChangelogScreen Widget', () {
    testWidgets('renders ChangelogScreen as Dialog with centered header and Close button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChangelogScreen(),
          ),
        ),
      );

      // Verify title & Dialog layout
      expect(find.text('Changelog'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Verify Close button exists underneath
      expect(find.text('Close'), findsOneWidget);

      // Verify header close icon is removed
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('dynamically widens dialog in landscape orientation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChangelogScreen(),
          ),
        ),
      );
      await tester.pump();

      // On 800px landscape, width is (800 * 0.85) = 680.0
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(ConstrainedBox),
        ),
      );
      final dialogBox = constrainedBoxes.firstWhere(
        (box) => box.constraints.minWidth == 680.0,
      );
      expect(dialogBox.constraints.maxWidth, 680.0);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dialog overflow prevention tests in landscape/constrained viewport', () {
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
