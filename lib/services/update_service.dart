import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_release_info.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/update/changelog_dialog.dart';
import '../widgets/update/update_dialog.dart';

// Re-export extracted models, parsers, and dialogs for seamless backward compatibility
export '../models/app_release_info.dart';
export '../models/categorized_changelog.dart';
export '../services/update_download_manager.dart';
export '../utils/changelog_parser.dart';
export '../widgets/update/changelog_dialog.dart';
export '../widgets/update/changelog_section_view.dart';
export '../widgets/update/update_dialog.dart';

/// Service coordinating GitHub release checks, APK updates, and release history.
class UpdateService {
  static const String owner = 'GamerJagdish';
  static const String repo = 'cardminder';

  /// Returns current version string e.g. "1.2.0"
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : '1.2.0';
    } catch (_) {
      return '1.2.0';
    }
  }

  /// Checks if the APK for the specified release is already downloaded and complete.
  static Future<File?> getCachedApkForRelease(AppReleaseInfo release) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;
      final file = File('${dir.path}/${release.apkFileName}');
      if (await file.exists()) {
        final length = await file.length();
        if (length > 1024 * 1024) {
          if (release.apkSizeBytes <= 0 ||
              (length - release.apkSizeBytes).abs() < 1024 * 1024) {
            return file;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Cleans up any older APK files except the one specified.
  static Future<void> cleanupOldApksExcept(String? keepFileName) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final list = dir.listSync();
      for (final item in list) {
        if (item is File && item.path.endsWith('.apk')) {
          final name = item.uri.pathSegments.last;
          if (keepFileName == null || name != keepFileName) {
            try {
              await item.delete();
            } catch (_) {}
          }
        } else if (item is File && item.path.endsWith('.download')) {
          try {
            await item.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Cleans up all downloaded APKs when the app is up to date on startup.
  static Future<void> cleanupOldApks() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final list = dir.listSync();
      for (final item in list) {
        if (item is File &&
            (item.path.endsWith('.apk') || item.path.endsWith('.download'))) {
          try {
            await item.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Fetches latest release metadata directly from GitHub API with asset details.
  static Future<AppReleaseInfo?> fetchReleaseDetails({
    List<String>? supportedAbis,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.userAgent = 'CardMinder-App';
      final uri = Uri.parse(
          'https://api.github.com/repos/$owner/$repo/releases/latest');
      final request = await client.getUrl(uri);
      request.headers
          .set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final respStr = await response.transform(utf8.decoder).join();
        final data = jsonDecode(respStr) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').trim();
        final version = tagName.startsWith('v.')
            ? tagName.substring(2)
            : tagName.startsWith('v')
                ? tagName.substring(1)
                : tagName;
        final body = (data['body'] as String? ?? '').trim();
        final assets = (data['assets'] as List<dynamic>?) ?? [];

        Map<String, dynamic>? targetAsset;

        // 1. Check supported ABIs
        if (supportedAbis != null && supportedAbis.isNotEmpty) {
          for (final abi in supportedAbis) {
            for (final a in assets) {
              final name = (a['name'] as String? ?? '').toLowerCase();
              if (name.endsWith('.apk') && name.contains(abi.toLowerCase())) {
                targetAsset = a as Map<String, dynamic>;
                break;
              }
            }
            if (targetAsset != null) break;
          }
        }

        // 2. Generic APK fallback
        if (targetAsset == null) {
          for (final a in assets) {
            final name = (a['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              targetAsset = a as Map<String, dynamic>;
              break;
            }
          }
        }

        if (targetAsset != null) {
          final apkUrl = (targetAsset['browser_download_url'] ??
                  targetAsset['url'] ??
                  '') as String;
          final apkFileName =
              targetAsset['name'] as String? ?? 'cardminder.apk';
          final apkSizeBytes = targetAsset['size'] as int? ?? 0;
          final publishedAtRaw =
              (data['published_at'] ?? data['created_at']) as String?;
          final publishedAt =
              publishedAtRaw != null ? DateTime.tryParse(publishedAtRaw) : null;

          return AppReleaseInfo(
            version: version,
            apkUrl: apkUrl,
            releaseNotes: body,
            apkFileName: apkFileName,
            apkSizeBytes: apkSizeBytes,
            publishedAt: publishedAt,
          );
        }
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
  }

  /// Checks GitHub releases for updates and displays result or full-screen update sheet.
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateMessage = true,
  }) async {
    if (!Platform.isAndroid) {
      if (context.mounted) {
        showAppSuccessSnackBar(
          context,
          title: 'Updates',
          message: 'In-app update is supported on Android devices.',
        );
      }
      return;
    }

    try {
      final updater = GithubReleaseApkUpdater();
      final supportedAbis = await updater.getSupportedAbis();

      AppReleaseInfo? release =
          await fetchReleaseDetails(supportedAbis: supportedAbis);

      if (release == null) {
        final apiService = GithubApiService();
        final fallbackRelease = await apiService.getLatestGithubAPKRelease(
          ownerGithub: owner,
          repositoryGithub: repo,
          apkKeyName: '',
          supportedAbis: supportedAbis,
        );

        if (fallbackRelease != null) {
          release = AppReleaseInfo(
            version: fallbackRelease.version,
            apkUrl: fallbackRelease.apkUrl,
            releaseNotes: fallbackRelease.releaseNote,
            apkFileName: 'cardminder-v${fallbackRelease.version}.apk',
            apkSizeBytes: 0,
          );
        }
      }

      if (release == null) {
        if (showNoUpdateMessage && context.mounted) {
          showAppSuccessSnackBar(
            context,
            title: 'Up to Date',
            message: 'You are using the latest version of CardMinder.',
          );
        }
        return;
      }

      var currentVersion = await updater.getCurrentAppVersion();
      if (currentVersion.trim().isEmpty) {
        currentVersion = await getAppVersion();
      }

      final isNewer = VersionComparator().isNewerVersion(
        release.version,
        currentVersion,
      );

      if (!context.mounted) return;

      if (isNewer) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogCtx) => UpdateScreen(
            release: release!,
            updater: updater,
            currentVersion: currentVersion,
          ),
        );
      } else {
        if (showNoUpdateMessage && context.mounted) {
          showAppSuccessSnackBar(
            context,
            title: 'Up to Date',
            message: 'CardMinder is up to date (v$currentVersion).',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppErrorSnackBar(
          context,
          title: 'Update Check Failed',
          message:
              'Unable to check for updates. Please check your internet connection.',
        );
      }
    }
  }

  /// Fetches paginated release history from GitHub releases API.
  static Future<List<AppReleaseInfo>> fetchReleasesHistory({
    int page = 1,
    int perPage = 5,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.userAgent = 'CardMinder-App';
      final uri = Uri.parse(
          'https://api.github.com/repos/$owner/$repo/releases?per_page=$perPage&page=$page');
      final request = await client.getUrl(uri);
      request.headers
          .set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final respStr = await response.transform(utf8.decoder).join();
        final list = jsonDecode(respStr) as List<dynamic>;
        final releases = <AppReleaseInfo>[];

        for (final item in list) {
          final data = item as Map<String, dynamic>;
          final tagName = (data['tag_name'] as String? ?? '').trim();
          final version = tagName.startsWith('v.')
              ? tagName.substring(2)
              : tagName.startsWith('v')
                  ? tagName.substring(1)
                  : tagName;
          final body = (data['body'] as String? ?? '').trim();
          final assets = (data['assets'] as List<dynamic>?) ?? [];

          String apkUrl = '';
          String apkFileName = 'cardminder-v$version.apk';
          int apkSizeBytes = 0;

          for (final a in assets) {
            final name = (a['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              apkUrl = (a['browser_download_url'] ?? a['url'] ?? '') as String;
              apkFileName = a['name'] as String? ?? apkFileName;
              apkSizeBytes = a['size'] as int? ?? 0;
              break;
            }
          }

          final publishedAtRaw =
              (data['published_at'] ?? data['created_at']) as String?;
          final publishedAt =
              publishedAtRaw != null ? DateTime.tryParse(publishedAtRaw) : null;

          releases.add(
            AppReleaseInfo(
              version: version,
              apkUrl: apkUrl,
              releaseNotes: body,
              apkFileName: apkFileName,
              apkSizeBytes: apkSizeBytes,
              publishedAt: publishedAt,
            ),
          );
        }

        return releases;
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return [];
  }

  /// Opens the full changelog dialog.
  static void showChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const ChangelogScreen(),
    );
  }
}
