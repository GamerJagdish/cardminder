import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/backup_dialogs.dart';
import 'notification_service.dart';

class AppReleaseInfo {
  final String version;
  final String apkUrl;
  final String releaseNotes;
  final String apkFileName;
  final int apkSizeBytes;
  final DateTime? publishedAt;

  AppReleaseInfo({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
    required this.apkFileName,
    required this.apkSizeBytes,
    this.publishedAt,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    if (publishedAt == null) return '';
    return DateFormat('MMM d, y').format(publishedAt!);
  }

  String get cleanVersion {
    if (version.startsWith('v.') || version.startsWith('V.')) {
      return version.substring(2);
    }
    if (version.startsWith('v') || version.startsWith('V')) {
      return version.substring(1);
    }
    return version;
  }

  String get architecture {
    final name = apkFileName.toLowerCase();
    if (name.contains('arm64-v8a') || name.contains('arm64')) {
      return 'arm64-v8a';
    } else if (name.contains('armeabi-v7a') || name.contains('armv7')) {
      return 'armeabi-v7a';
    } else if (name.contains('x86_64')) {
      return 'x86_64';
    } else if (name.contains('x86')) {
      return 'x86';
    } else if (name.contains('universal') || name.contains('all-devices')) {
      return 'universal';
    }
    return '';
  }

  String get displayTitle {
    final arch = architecture;
    if (arch.isNotEmpty) {
      return 'CardMinder $cleanVersion ($arch)';
    }
    return 'CardMinder $cleanVersion';
  }
}

class CategorizedChangelog {
  final Map<String, List<String>> categories;

  CategorizedChangelog(this.categories);

  bool get isEmpty => categories.isEmpty;
}

class ChangelogParser {
  static CategorizedChangelog parse(String raw) {
    if (raw.trim().isEmpty) return CategorizedChangelog({});

    final lines = raw.split('\n');
    final Map<String, List<String>> groups = {
      'refactor:': [],
      'feature:': [],
      'fix:': [],
      'chore:': [],
      'other:': [],
    };

    String? currentCategory;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final isIndented = line.startsWith('  ') || line.startsWith('\t');
      var trimmed = line.trim();

      // Ignore markdown headers
      if (trimmed.startsWith('#')) continue;

      // Ignore full changelog comparisons / links
      if (trimmed.toLowerCase().contains('full changelog')) continue;
      if (trimmed.toLowerCase().contains('compare/')) continue;
      if (trimmed.toLowerCase().startsWith('see full')) continue;

      // Check if this line looks like a commit header (contains author / commit URL)
      final hasCommitMeta =
          RegExp(r'\s+by\s+@\S+', caseSensitive: false).hasMatch(trimmed) ||
              RegExp(r'\s+in\s+https?://\S+', caseSensitive: false)
                  .hasMatch(trimmed);

      // Remove bullet list characters (*, -, +, 1., 2.)
      trimmed = trimmed.replaceFirst(RegExp(r'^[\*\-\+]\s+'), '');
      trimmed = trimmed.replaceFirst(RegExp(r'^\d+[\.\)]\s+'), '');

      // Strip markdown bold/italics/code markers
      trimmed = trimmed
          .replaceAll('**', '')
          .replaceAll('__', '')
          .replaceAll('`', '');

      // Strip PR / commit / author suffixes
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s+in\s+https?://\S+', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s+by\s+@\S+', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'\s*\(\#\d+\)', caseSensitive: false), '');
      trimmed = trimmed.replaceFirst(
          RegExp(r'https?://github\.com/\S+', caseSensitive: false), '');

      trimmed = trimmed.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();
      String? matchedCategory;
      String content = trimmed;

      if (lower.startsWith('feat:') ||
          lower.startsWith('feat!:') ||
          lower.startsWith('feature:')) {
        matchedCategory = 'feature:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('fix:') ||
          lower.startsWith('fix!:') ||
          lower.startsWith('bugfix:')) {
        matchedCategory = 'fix:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('refactor:') ||
          lower.startsWith('refactor!:') ||
          lower.startsWith('perf:') ||
          lower.startsWith('perf!:')) {
        matchedCategory = 'refactor:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (lower.startsWith('chore:') ||
          lower.startsWith('chore!:') ||
          lower.startsWith('docs:') ||
          lower.startsWith('style:') ||
          lower.startsWith('test:') ||
          lower.startsWith('ci:') ||
          lower.startsWith('build:') ||
          lower.startsWith('revert:')) {
        matchedCategory = 'chore:';
        content = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      }

      if (matchedCategory != null) {
        currentCategory = matchedCategory;
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          if (!groups[currentCategory]!.contains(content)) {
            groups[currentCategory]!.add(content);
          }
        }
      } else if ((isIndented || !hasCommitMeta) &&
          currentCategory != null &&
          groups[currentCategory]!.isNotEmpty) {
        // Description sub-bullet belonging to the previous entry
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          final parentIdx = groups[currentCategory]!.length - 1;
          groups[currentCategory]![parentIdx] += '\n   • $content';
        }
      } else {
        currentCategory = 'other:';
        if (content.isNotEmpty) {
          content = content[0].toUpperCase() + content.substring(1);
          if (!groups['other:']!.contains(content)) {
            groups['other:']!.add(content);
          }
        }
      }
    }

    // Keep only populated categories in order
    final result = <String, List<String>>{};
    for (final key in ['refactor:', 'feature:', 'fix:', 'chore:', 'other:']) {
      if (groups[key]!.isNotEmpty) {
        result[key] = groups[key]!;
      }
    }

    return CategorizedChangelog(result);
  }
}

class ChangelogSectionHelper {
  static String categoryTitle(String key) {
    switch (key) {
      case 'feature:':
        return 'Features';
      case 'fix:':
        return 'Bug Fixes';
      case 'refactor:':
        return 'Improvements';
      case 'chore:':
        return 'Maintenance';
      case 'other:':
      default:
        return 'Other Changes';
    }
  }

  static Color categoryColor(String key) {
    switch (key) {
      case 'feature:':
        return AppTheme.accentEmerald;
      case 'fix:':
        return const Color(0xFFF43F5E); // Rose 500
      case 'refactor:':
        return const Color(0xFF38BDF8); // Sky 400
      case 'chore:':
        return const Color(0xFFA78BFA); // Violet 400
      case 'other:':
      default:
        return const Color(0xFF94A3B8); // Slate 400
    }
  }

  static Widget buildCategorizedNotes({
    required BuildContext context,
    required CategorizedChangelog changelog,
    required String rawNotes,
    required bool isDark,
  }) {
    if (changelog.isEmpty) {
      final fallback = rawNotes.trim().isNotEmpty
          ? rawNotes.trim()
          : 'Performance enhancements and bug fixes.';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          fallback,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            letterSpacing: 0.15,
            color: isDark
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF334155),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in changelog.categories.entries) ...[
          // Category Pill Badge
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: categoryColor(entry.key)
                  .withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: categoryColor(entry.key)
                    .withValues(alpha: isDark ? 0.28 : 0.20),
                width: 0.8,
              ),
            ),
            child: Text(
              categoryTitle(entry.key),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: categoryColor(entry.key),
                letterSpacing: 0.3,
              ),
            ),
          ),
          // List of items in this category
          for (int i = 0; i < entry.value.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12, right: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8.5, right: 10, left: 2),
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Expanded(
                    child: _buildItemContent(entry.value[i], isDark),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  static Widget _buildItemContent(String rawItem, bool isDark) {
    if (rawItem.contains('\n')) {
      final parts = rawItem.split('\n');
      final title = parts.first;
      final subLines = parts.sublist(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.50,
              letterSpacing: 0.15,
              color: isDark
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
          for (final sub in subLines)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                sub.trim(),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.50,
                  letterSpacing: 0.1,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      );
    }

    return Text(
      rawItem,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        letterSpacing: 0.15,
        color: isDark
            ? const Color(0xFFCBD5E1)
            : const Color(0xFF334155),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class UpdateDownloadManager extends ChangeNotifier {
  static final UpdateDownloadManager instance = UpdateDownloadManager._();
  UpdateDownloadManager._();

  AppReleaseInfo? currentRelease;
  bool isDownloading = false;
  double progress = 0.0;
  String statusText = '';
  String? downloadedApkPath;
  HttpClient? _currentClient;
  bool _isCancelled = false;
  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> startDownload(AppReleaseInfo release) async {
    if (isDownloading) return;

    currentRelease = release;
    isDownloading = true;
    progress = 0.0;
    statusText = 'Preparing download...';
    downloadedApkPath = null;
    _isCancelled = false;
    notifyListeners();

    IOSink? sink;
    File? partialFile;

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception('Storage directory not available');
      }

      await UpdateService.cleanupOldApksExcept(release.apkFileName);

      final finalFilePath = '${extDir.path}/${release.apkFileName}';
      final tempFilePath = '$finalFilePath.download';
      partialFile = File(tempFilePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }

      _currentClient = HttpClient();
      _currentClient!.userAgent = 'CardMinder-App';
      final uri = Uri.parse(release.apkUrl);
      final request = await _currentClient!.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      final response = await request.close();

      if (response.statusCode != 200 &&
          response.statusCode != 302 &&
          response.statusCode != 206) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength > 0
          ? response.contentLength
          : release.apkSizeBytes;

      sink = partialFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response) {
        if (_isCancelled) {
          break;
        }
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (contentLength > 0) {
          progress = receivedBytes / contentLength;
          final percent = (progress * 100).toInt().clamp(0, 100);
          final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMb = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          statusText = '$percent% ($receivedMb / $totalMb MB)';

          final now = DateTime.now();
          if (now.difference(_lastNotificationTime).inMilliseconds >= 600) {
            _lastNotificationTime = now;
            NotificationService.showDownloadProgressNotification(
              versionName: release.version,
              progressPercent: percent,
              progressText: '$percent% ($receivedMb / $totalMb MB)',
            );
          }
        } else {
          final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
          statusText = '$receivedMb MB downloaded';
        }
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (_isCancelled) {
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
        statusText = 'Download cancelled';
        isDownloading = false;
        notifyListeners();
        await NotificationService.cancelUpdateNotification();
        return;
      }

      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partialFile.rename(finalFilePath);

      downloadedApkPath = finalFilePath;
      isDownloading = false;
      progress = 1.0;
      statusText = 'Download complete';
      notifyListeners();

      await NotificationService.showDownloadCompleteNotification(
        versionName: release.version,
        filePath: finalFilePath,
      );
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (partialFile != null && await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      isDownloading = false;
      statusText = 'Download error: $e';
      notifyListeners();
      await NotificationService.cancelUpdateNotification();
    } finally {
      _currentClient?.close(force: true);
      _currentClient = null;
    }
  }

  void cancelDownload() {
    if (!isDownloading) return;
    _isCancelled = true;
    isDownloading = false;
    _currentClient?.close(force: true);
    _currentClient = null;
    notifyListeners();
    NotificationService.cancelUpdateNotification();
  }
}

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

class UpdateScreen extends StatefulWidget {
  final AppReleaseInfo release;
  final GithubReleaseApkUpdater updater;
  final String currentVersion;

  const UpdateScreen({
    super.key,
    required this.release,
    required this.updater,
    required this.currentVersion,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateDownloadManager _downloadManager =
      UpdateDownloadManager.instance;
  String? _cachedApkPath;

  @override
  void initState() {
    super.initState();
    _downloadManager.addListener(_onDownloadStateChanged);
    _checkCachedApk();
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _onDownloadStateChanged() {
    if (mounted) {
      setState(() {
        if (_downloadManager.downloadedApkPath != null) {
          _cachedApkPath = _downloadManager.downloadedApkPath;
        }
      });
    }
  }

  Future<void> _checkCachedApk() async {
    final cached =
        await UpdateService.getCachedApkForRelease(widget.release);
    if (mounted) {
      setState(() {
        _cachedApkPath = cached?.path ?? _downloadManager.downloadedApkPath;
      });
    }
  }

  Future<void> _installApk() async {
    final path = _cachedApkPath;
    if (path != null && await File(path).exists()) {
      await widget.updater.installApk(path);
    } else {
      _startDownload();
    }
  }

  void _startDownload() {
    _downloadManager.startDownload(widget.release);
  }

  void _cancelDownload() {
    _downloadManager.cancelDownload();
    setState(() {
      _cachedApkPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changelog = ChangelogParser.parse(widget.release.releaseNotes);
    final isDownloading = _downloadManager.isDownloading;
    final isReadyToInstall = _cachedApkPath != null && !isDownloading;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final horizontalInset = screenWidth < 500 ? 16.0 : 24.0;
    final availableWidth = screenWidth - (horizontalInset * 2);

    final double dialogWidth;
    if (screenWidth >= 1000) {
      dialogWidth = 640.0;
    } else if (screenWidth >= 600) {
      dialogWidth = (screenWidth * 0.70).clamp(480.0, 620.0);
    } else {
      dialogWidth = availableWidth;
    }
    final targetWidth = dialogWidth.clamp(0.0, availableWidth);

    return PopScope(
      canPop: true,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: 24,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.90,
            maxWidth: targetWidth,
            minWidth: targetWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Bar: Header (Centered, no icon, no divider)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Center(
                  child: Text(
                    'Update Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 2. Scrollable Body
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  children: [
                    // Hero Card: CardMinder <version> (<arch>) -> (date + size)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.release.displayTitle,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.release.formattedDate.isNotEmpty ||
                              widget.release.formattedSize.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            // Date pill and then Size pill together
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: [
                                if (widget.release.formattedDate.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          widget.release.formattedDate,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.release.formattedSize.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.storage_rounded,
                                          size: 13,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          widget.release.formattedSize,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // "What's New" Section Header (Centered, muted, easy on eyes)
                    Center(
                      child: Text(
                        "WHAT'S NEW",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Categorized Release Notes
                    ChangelogSectionHelper.buildCategorizedNotes(
                      context: context,
                      changelog: changelog,
                      rawNotes: widget.release.releaseNotes,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // 3. Sticky Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: isDownloading
                          ? _buildMorphingProgressButton(context, isDark)
                          : (isReadyToInstall
                              ? _buildInstallButton(context, isDark)
                              : _buildInitialDownloadButton(context, isDark)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialDownloadButton(BuildContext context, bool isDark) {
    return SizedBox(
      key: const ValueKey('initial_download_btn'),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _startDownload,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Center(
          child: Text(
            'Download',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMorphingProgressButton(BuildContext context, bool isDark) {
    final progress = _downloadManager.progress.clamp(0.0, 1.0);
    final percentInt = (progress * 100).toInt();

    String sizeInfo = _downloadManager.statusText;
    if (sizeInfo.contains('(') && sizeInfo.contains(')')) {
      final startIndex = sizeInfo.indexOf('(') + 1;
      final endIndex = sizeInfo.lastIndexOf(')');
      if (endIndex > startIndex) {
        sizeInfo = sizeInfo.substring(startIndex, endIndex).trim();
      }
    }

    return LayoutBuilder(
      key: const ValueKey('morphing_progress_btn'),
      builder: (context, constraints) {
        final fillWidth =
            (constraints.maxWidth * progress).clamp(0.0, constraints.maxWidth);

        return Container(
          height: 50,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: fillWidth > 0 ? fillWidth : 0.0,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald
                        .withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Downloading...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$percentInt%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentEmerald,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          if (sizeInfo.isNotEmpty)
                            Text(
                              sizeInfo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Tooltip(
                      message: 'Cancel download',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _cancelDownload,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstallButton(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('install_action_btn'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentEmerald.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 17, color: AppTheme.accentEmerald),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Update downloaded and verified',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentEmerald,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _installApk,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentEmerald,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_update_rounded, size: 21),
                SizedBox(width: 8),
                Text(
                  'Install Update',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  final List<AppReleaseInfo> _allFetchedReleases = [];
  int _displayedCount = 5;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreServerPages = true;
  int _serverPage = 1;
  String _currentVersion = '';
  String? _errorMessage;

  static const int _serverPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  bool get _hasMore =>
      _displayedCount < _allFetchedReleases.length || _hasMoreServerPages;

  List<AppReleaseInfo> get _displayedReleases =>
      _allFetchedReleases.take(_displayedCount).toList();

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allFetchedReleases.clear();
      _displayedCount = 5;
      _serverPage = 1;
      _hasMoreServerPages = true;
    });

    try {
      final currentVer = await UpdateService.getAppVersion();
      final items = await UpdateService.fetchReleasesHistory(
        page: 1,
        perPage: _serverPerPage,
      );

      if (mounted) {
        setState(() {
          _currentVersion = currentVer;
          _allFetchedReleases.addAll(items);
          _hasMoreServerPages = items.length >= _serverPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to load changelog. Please check your internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final targetCount = _displayedCount + 20;

    // If we already have enough releases in memory, just expand display count
    if (_allFetchedReleases.length >= targetCount || !_hasMoreServerPages) {
      setState(() {
        _displayedCount = targetCount;
      });
      return;
    }

    // Otherwise fetch next page from server
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _serverPage + 1;
      final newItems = await UpdateService.fetchReleasesHistory(
        page: nextPage,
        perPage: _serverPerPage,
      );

      if (mounted) {
        setState(() {
          _serverPage = nextPage;
          for (final item in newItems) {
            if (!_allFetchedReleases.any((r) => r.version == item.version)) {
              _allFetchedReleases.add(item);
            }
          }
          _hasMoreServerPages = newItems.length >= _serverPerPage;
          _displayedCount = targetCount;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayedCount = targetCount;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final horizontalInset = screenWidth < 500 ? 16.0 : 24.0;
    final availableWidth = screenWidth - (horizontalInset * 2);

    final double dialogWidth;
    if (screenWidth >= 1000) {
      dialogWidth = 640.0;
    } else if (screenWidth >= 600) {
      dialogWidth = (screenWidth * 0.70).clamp(480.0, 620.0);
    } else {
      dialogWidth = availableWidth;
    }
    final targetWidth = dialogWidth.clamp(0.0, availableWidth);

    return PopScope(
      canPop: true,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: 24,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.90,
            maxWidth: targetWidth,
            minWidth: targetWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Bar: Header (Centered, no icon, no divider)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Center(
                  child: Text(
                    'Changelog',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 2. Body List
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded,
                                      size: 48, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadInitialData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _displayedReleases.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text(
                                    'No release notes found.',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 18),
                                itemCount: _displayedReleases.length + 1,
                                itemBuilder: (context, index) {
                                  // Bottom Load More / Completed item
                                  if (index == _displayedReleases.length) {
                                    if (_hasMore) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8, bottom: 12),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: _isLoadingMore
                                                ? null
                                                : _loadMore,
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: _isLoadingMore
                                                ? SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Load More',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12, bottom: 16),
                                        child: Center(
                                          child: Text(
                                            "You've reached the beginning of the changelog",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }

                                  final release = _displayedReleases[index];
                                  final isCurrent =
                                      release.version == _currentVersion;
                                  final changelog = ChangelogParser.parse(
                                      release.releaseNotes);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppTheme.accentEmerald
                                                .withValues(alpha: 0.5)
                                            : isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFE2E8F0),
                                        width: isCurrent ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Version Title Row
                                        Row(
                                          children: [
                                            Text(
                                              'version ${release.version}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentEmerald
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'current',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.accentEmerald,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            if (release
                                                .formattedDate.isNotEmpty)
                                              Text(
                                                release.formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Categorized notes
                                        ChangelogSectionHelper.buildCategorizedNotes(
                                          context: context,
                                          changelog: changelog,
                                          rawNotes: release.releaseNotes,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),

              // 3. Sticky Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
