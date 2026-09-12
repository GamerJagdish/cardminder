import 'package:flutter/material.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';

/// Modal dialog that renders paginated GitHub releases and changelog history.
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
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    ScrollConfiguration(
                                      behavior:
                                          ScrollConfiguration.of(context)
                                              .copyWith(scrollbars: false),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 6, 20, 24),
                                        itemCount:
                                            _displayedReleases.length + 1,
                                        itemBuilder: (context, index) {
                                          // Bottom Load More / Completed item
                                          if (index ==
                                              _displayedReleases.length) {
                                            if (_hasMore) {
                                              final buttonBg = isDark
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFFF1F5F9);
                                              final buttonBorder = isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFE2E8F0);
                                              final buttonFg = isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF475569);

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4, bottom: 12),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton(
                                                    onPressed: _isLoadingMore
                                                        ? null
                                                        : _loadMore,
                                                    style: OutlinedButton.styleFrom(
                                                      backgroundColor: buttonBg,
                                                      disabledBackgroundColor: buttonBg,
                                                      foregroundColor: buttonFg,
                                                      disabledForegroundColor:
                                                          buttonFg.withValues(alpha: 0.6),
                                                      side: BorderSide(
                                                        color: buttonBorder,
                                                        width: 1.0,
                                                      ),
                                                      padding: const EdgeInsets.symmetric(
                                                          vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(14),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: _isLoadingMore
                                                        ? SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2.0,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<Color>(
                                                                buttonFg,
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            'Load More',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              color: buttonFg,
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
                                                          .withValues(
                                                              alpha: 0.8),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }

                                          final release =
                                              _displayedReleases[index];
                                          final isCurrent = release.version ==
                                              _currentVersion;
                                          final changelog =
                                              ChangelogParser.parse(
                                                  release.releaseNotes);

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: isCurrent
                                                    ? AppTheme.accentEmerald
                                                        .withValues(alpha: 0.5)
                                                    : isDark
                                                        ? const Color(
                                                            0xFF1E293B)
                                                        : const Color(
                                                            0xFFE2E8F0),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    if (isCurrent) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppTheme
                                                              .accentEmerald
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: AppTheme
                                                              .accentEmerald
                                                              .withValues(
                                                                  alpha: 0.3),
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'current',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppTheme
                                                              .accentEmerald,
                                                            letterSpacing: 0.5,
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
                                                              ? const Color(
                                                                  0xFF94A3B8)
                                                              : const Color(
                                                                  0xFF64748B),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),

                                                // Categorized notes
                                                ChangelogSectionHelper
                                                    .buildCategorizedNotes(
                                                  context: context,
                                                  changelog: changelog,
                                                  rawNotes:
                                                      release.releaseNotes,
                                                  isDark: isDark,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
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
