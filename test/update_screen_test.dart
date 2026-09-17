import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardminder/services/update_service.dart';
import 'package:cardminder/theme/app_theme.dart';
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

      // Verify What's New section and action buttons
      expect(find.text("WHAT'S NEW"), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
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

    testWidgets('renders UpdateScreen in landscape orientation without layout errors',
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
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ChangelogScreen Widget', () {
    testWidgets('renders ChangelogScreen as Dialog with Close button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChangelogScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify title & Dialog layout
      expect(find.text('Changelog'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders ChangelogScreen in landscape orientation without layout errors',
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

      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });


}
