import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/backup_dialogs.dart';

class UpdateService {
  static const String owner = 'GamerJagdish';
  static const String repo = 'cardminder';

  /// Returns current version string e.g. "1.2.0"
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.2.0';
    }
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
      final apiService = GithubApiService();

      final supportedAbis = await updater.getSupportedAbis();
      final release = await apiService.getLatestGithubAPKRelease(
        ownerGithub: owner,
        repositoryGithub: repo,
        apkKeyName: '',
        supportedAbis: supportedAbis,
      );

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
            release: release,
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
          message: 'Unable to check for updates. Please check your internet connection.',
        );
      }
    }
  }
}

class _UpdateAvailableDialog extends StatefulWidget {
  final dynamic release;
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
          _statusText = 'Error: ';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: AppTheme.accentEmerald,
                    size: 24,
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
                        'v → v',
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
            const SizedBox(height: 16),
            Text(
              'A new version of CardMinder is available for download.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 18),
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
            const SizedBox(height: 22),
            Row(
              children: [
                if (!_isDownloading)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
