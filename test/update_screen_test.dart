import 'package:cardminder/services/update_service.dart';
import 'package:cardminder/theme/app_theme.dart';
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
  });

  group('UpdateScreen Widget', () {
    final release = AppReleaseInfo(
      version: '1.2.5',
      apkUrl: 'https://example.com/cardminder.apk',
      releaseNotes: "## What's Changed\n* feat: shiny new feature",
      apkFileName: 'cardminder-v1.2.5.apk',
      apkSizeBytes: 27892121,
      publishedAt: DateTime(2026, 9, 5),
    );

    tearDown(() {
      UpdateDownloadManager.instance.isDownloading = false;
      UpdateDownloadManager.instance.progress = 0.0;
      UpdateDownloadManager.instance.statusText = '';
      UpdateDownloadManager.instance.downloadedApkPath = null;
    });

    testWidgets('renders initial UpdateScreen correctly without Later button',
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
      expect(find.text('CardMinder'), findsOneWidget);
      expect(find.text('cardminder-v1.2.5.apk'), findsOneWidget);

      // Verify version progression and badges
      expect(find.text('v1.2.4 -> v1.2.5'), findsOneWidget);
      expect(find.text('26.6 MB'), findsOneWidget);
      expect(find.text('Sep 5, 2026'), findsOneWidget);

      // Verify download button exists with size
      expect(find.text('Download Update (26.6 MB)'), findsOneWidget);

      // Verify that "Later" button is removed
      expect(find.text('Later'), findsNothing);

      // Verify close button exists
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
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
      expect(
        find.text('Dismissing will continue downloading in background'),
        findsOneWidget,
      );

      // Tap inline 'X' cancel button inside progress button
      final cancelBtn = find.byTooltip('Cancel download');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Download is cancelled and button smoothly reverts to initial download button
      expect(UpdateDownloadManager.instance.isDownloading, isFalse);
      expect(find.byKey(const ValueKey('initial_download_btn')), findsOneWidget);
      expect(find.text('Download Update (26.6 MB)'), findsOneWidget);
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
    });
  });
}
