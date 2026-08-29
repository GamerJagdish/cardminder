import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/backup_dialogs.dart';

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

  /// Checks GitHub releases for updates and displays result or dialog.
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

      // 1. Fetch release details including file name, size, and notes
      AppReleaseInfo? release =
          await fetchReleaseDetails(supportedAbis: supportedAbis);

      // Fallback to plugin api service if direct fetch failed
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
          barrierDismissible: false,
          builder: (dialogCtx) => _UpdateAvailableDialog(
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

class _UpdateAvailableDialog extends StatefulWidget {
  final AppReleaseInfo release;
  final GithubReleaseApkUpdater updater;
  final String currentVersion;

  const _UpdateAvailableDialog({
    required this.release,
    required this.updater,
    required this.currentVersion,
  });

  @override
  State<_UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<_UpdateAvailableDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Downloading update...';
    });

    try {
      final downloader = ApkDownloaderService();
      final filePath = await downloader.downloadAPK(
        widget.release.apkUrl,
        null,
        (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
              final percent = (_progress * 100).toInt();
              final receivedMb = (received / (1024 * 1024)).toStringAsFixed(1);
              final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
              _statusText = '$percent% ($receivedMb / $totalMb MB)';
            });
          }
        },
      );

      if (filePath != null) {
        if (mounted) {
          setState(() {
            _statusText = 'Opening installer...';
          });
        }
        await widget.updater.installApk(filePath);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _statusText = 'Download failed. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final releaseNotes = widget.release.releaseNotes.trim();

    return Dialog(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.currentVersion}  →  v${widget.release.version}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. APK File & Size info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.android_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.release.apkFileName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.release.formattedSize.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.release.formattedSize,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Release Notes / Changelog
            Text(
              "What's New:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  releaseNotes.isNotEmpty
                      ? releaseNotes
                      : 'Performance improvements and bug fixes.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),

            // 4. Download progress or error
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
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
                _statusText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ] else if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentRose,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 5. Actions: Later & Update Now
            Row(
              children: [
                if (!_isDownloading)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                if (!_isDownloading) const SizedBox(width: 10),
                Expanded(
                  flex: _isDownloading ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownloadAndInstall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.primaryAccentDark
                          : AppTheme.primaryNavy,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isDownloading ? 'Downloading...' : 'Update Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
