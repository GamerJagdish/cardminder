import 'dart:io';
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';

/// Modal dialog that presents an available app update and handles downloading and installation.
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
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final horizontalInset = screenWidth < 500 ? 16.0 : 24.0;
    final verticalInset = isLandscape || screenHeight < 500 ? 12.0 : 24.0;
    final availableWidth = screenWidth - (horizontalInset * 2);

    final double dialogWidth;
    if (isLandscape) {
      if (screenWidth >= 1100) {
        dialogWidth = 860.0;
      } else if (screenWidth >= 650) {
        dialogWidth = (screenWidth * 0.85).clamp(560.0, 820.0);
      } else {
        dialogWidth = availableWidth;
      }
    } else {
      if (screenWidth >= 1000) {
        dialogWidth = 640.0;
      } else if (screenWidth >= 600) {
        dialogWidth = (screenWidth * 0.72).clamp(480.0, 620.0);
      } else {
        dialogWidth = availableWidth;
      }
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
          vertical: verticalInset,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * (isLandscape ? 0.94 : 0.90),
            maxWidth: targetWidth,
            minWidth: targetWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Bar: Header (Centered, no icon, no divider)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  isLandscape ? 14 : 22,
                  20,
                  isLandscape ? 10 : 16,
                ),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
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
                      BottomScrollHintOverlay(isDark: isDark),
                    ],
                  ),
                ),
              ),

              // 3. Sticky Bottom Action Bar
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  isLandscape ? 8 : 10,
                  20,
                  isLandscape ? 10 : 16,
                ),
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
