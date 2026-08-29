import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
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

  AppReleaseInfo({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
    required this.apkFileName,
    required this.apkSizeBytes,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class ChangelogParser {
  static List<String> parse(String raw) {
    if (raw.trim().isEmpty) return [];

    final lines = raw.split('\n');
    final points = <String>[];

    for (var line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Ignore markdown headers
      if (trimmed.startsWith('#')) continue;

      // Ignore full changelog comparisons / links
      if (trimmed.toLowerCase().contains('full changelog')) continue;
      if (trimmed.toLowerCase().contains('compare/')) continue;
      if (trimmed.toLowerCase().startsWith('see full')) continue;

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

      // Strip conventional commit prefixes
      final prefixes = [
        'feat:',
        'fix:',
        'chore:',
        'refactor:',
        'perf:',
        'docs:',
        'style:',
        'test:',
        'ci:',
        'build:',
        'revert:',
        'feat!:',
        'fix!:',
        'chore!:',
      ];
      for (final p in prefixes) {
        if (trimmed.toLowerCase().startsWith(p)) {
          trimmed = trimmed.substring(p.length).trim();
          break;
        }
      }

      trimmed = trimmed.trim();
      if (trimmed.isNotEmpty) {
        // Capitalize first character
        trimmed = trimmed[0].toUpperCase() + trimmed.substring(1);
        if (!points.contains(trimmed)) {
          points.add(trimmed);
        }
      }
    }

    return points;
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
    _currentClient?.close(force: true);
    _currentClient = null;
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

          return AppReleaseInfo(
            version: version,
            apkUrl: apkUrl,
            releaseNotes: body,
            apkFileName: apkFileName,
            apkSizeBytes: apkSizeBytes,
          );
        }
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
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
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
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
    final changelogPoints = ChangelogParser.parse(widget.release.releaseNotes);
    final isDownloading = _downloadManager.isDownloading;
    final isReadyToInstall = _cachedApkPath != null && !isDownloading;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Top Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.system_update_alt_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Software Update',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textMuted,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              children: [
                // Hero Banner
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
                        'CardMinder Update',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Version Comparison Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'v${widget.currentVersion}  ➔  v${widget.release.version}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentEmerald,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // APK File & Size chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.android_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.release.apkFileName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.release.formattedSize.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${widget.release.formattedSize}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // "What's New" Section Header
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppTheme.accentEmerald,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "WHAT'S NEW",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Formatted Changelog Points
                if (changelogPoints.isNotEmpty)
                  ...changelogPoints.map((point) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentEmerald
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: AppTheme.accentEmerald,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      widget.release.releaseNotes.trim().isNotEmpty
                          ? widget.release.releaseNotes.trim()
                          : 'Performance enhancements and bug fixes.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadManager.progress > 0
                            ? _downloadManager.progress
                            : null,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentEmerald),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadManager.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_downward_rounded,
                                size: 16),
                            label: const Text(
                              'Download in Background',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _cancelDownload,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accentRose,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ] else if (isReadyToInstall) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: AppTheme.accentEmerald),
                          SizedBox(width: 8),
                          Text(
                            'Package ready to install (No download needed)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _installApk,
                        icon: const Icon(Icons.system_update_rounded,
                            size: 18),
                        label: const Text(
                          'Install Update Now',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentEmerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _startDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppTheme.primaryAccentDark
                                  : AppTheme.primaryNavy,
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Download & Update',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
