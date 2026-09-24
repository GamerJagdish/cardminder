import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../providers/card_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/home_view.dart';

/// Full-screen Theme Preview experience with animated GLSL shaders,
/// horizontal smartphone mockup carousel, dynamic edge-sliding Variants button, and quick Mode controls.
class ThemePreviewScreen extends ConsumerStatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  ConsumerState<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends ConsumerState<ThemePreviewScreen> {
  late PageController _pageController;
  late PageController _landscapePageController;
  PageController? _variantPageController;
  PageController? _landscapeVariantPageController;
  late int _currentPage;
  int _currentVariantIndex = 0;
  bool _isViewingVariants = false;
  AppThemePreset? _activeVariantsParent;
  late Map<String, String> _selectedVariants;

  bool _isReadyForShader = false;
  bool _isClosing = false;
  bool _isCarouselAnimating = false;
  bool _isProgrammaticAnimating = false;
  Animation<double>? _routeAnimation;
  Timer? _transitionFallbackTimer;

  final List<AppThemePreset> _presets = ThemePresets.all;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _selectedVariants = Map<String, String>.from(settings.selectedVariants);

    final parent = ThemePresets.findParentOrSelf(settings.themePreset);
    if (parent.hasVariants) {
      _selectedVariants[parent.id] = settings.themePreset;
    }
    final initialIndex = _presets.indexWhere((p) => p.id == parent.id);
    _currentPage = initialIndex >= 0 ? initialIndex : 0;

    _pageController = PageController(
      viewportFraction: 0.72,
      initialPage: _currentPage,
    );
    _landscapePageController = PageController(
      viewportFraction: 0.45,
      initialPage: _currentPage,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      if (_routeAnimation != modalRoute.animation) {
        _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
        _routeAnimation = modalRoute.animation;
        if (_routeAnimation != null) {
          if (_routeAnimation!.isCompleted) {
            _isReadyForShader = true;
          } else {
            _isReadyForShader = false;
            _routeAnimation!.addStatusListener(_onRouteAnimationStatusChanged);
            _setupFallbackTimer();
          }
        } else {
          _isReadyForShader = true;
        }
      }
    } else {
      _isReadyForShader = true;
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _transitionFallbackTimer?.cancel();
      if (mounted && !_isClosing && !_isReadyForShader) {
        setState(() {
          _isReadyForShader = true;
        });
      }
    } else if (status == AnimationStatus.reverse) {
      if (mounted && !_isClosing) {
        setState(() {
          _isClosing = true;
          _isReadyForShader = false;
        });
      }
    }
  }

  void _setupFallbackTimer() {
    _transitionFallbackTimer?.cancel();
    _transitionFallbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_isClosing && !_isReadyForShader) {
        setState(() {
          _isReadyForShader = true;
        });
      }
    });
  }

  void _handleClose(BuildContext context) {
    HapticFeedback.lightImpact();
    if (_isViewingVariants) {
      _exitVariantsView();
      return;
    }
    // Stop the shader animation immediately upon close tap
    // so the reverse slide-down route transition runs with 0 GPU lag.
    if (mounted) {
      setState(() {
        _isClosing = true;
        _isReadyForShader = false;
      });
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _transitionFallbackTimer?.cancel();
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _pageController.dispose();
    _landscapePageController.dispose();
    _variantPageController?.dispose();
    _landscapeVariantPageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isViewingVariants) return;
    if (_currentPage == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = index;
    });

    if (_pageController.hasClients && _pageController.page?.round() != index) {
      _pageController.jumpToPage(index);
    }
    if (_landscapePageController.hasClients && _landscapePageController.page?.round() != index) {
      _landscapePageController.jumpToPage(index);
    }

    final selectedPreset = _presets[index];
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    String targetId = selectedPreset.id;
    if (selectedPreset.hasVariants) {
      final rememberedId = _selectedVariants[selectedPreset.id] ?? settings.selectedVariants[selectedPreset.id];
      final isMatch = rememberedId != null && selectedPreset.variants.any((v) => v.id == rememberedId);
      targetId = isMatch ? rememberedId : selectedPreset.variants.first.id;
      _selectedVariants[selectedPreset.id] = targetId;
    }

    ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(
            themePreset: targetId,
            selectedVariants: _selectedVariants,
          ),
          cards,
        );
  }

  void _enterVariantsView(AppThemePreset parent) {
    HapticFeedback.mediumImpact();
    final settings = ref.read(settingsNotifierProvider);
    final currentTarget = _selectedVariants[parent.id] ?? settings.themePreset;
    final variantIndex = parent.variants.indexWhere((v) => v.id == currentTarget);
    final idx = variantIndex >= 0 ? variantIndex : 0;

    _variantPageController?.dispose();
    _variantPageController = PageController(
      viewportFraction: 0.72,
      initialPage: idx,
    );
    _landscapeVariantPageController?.dispose();
    _landscapeVariantPageController = PageController(
      viewportFraction: 0.45,
      initialPage: idx,
    );

    final selectedVariant = parent.variants[idx];
    _selectedVariants[parent.id] = selectedVariant.id;

    setState(() {
      _isViewingVariants = true;
      _activeVariantsParent = parent;
      _currentVariantIndex = idx;
    });

    if (selectedVariant.id != settings.themePreset) {
      final cards = ref.read(cardNotifierProvider).cards;
      ref.read(settingsNotifierProvider.notifier).updateSettings(
            settings.copyWith(
              themePreset: selectedVariant.id,
              selectedVariants: _selectedVariants,
            ),
            cards,
          );
    }
  }

  void _exitVariantsView() {
    HapticFeedback.lightImpact();
    final parent = _activeVariantsParent;
    int targetIndex = _currentPage;
    if (parent != null) {
      final pIndex = _presets.indexWhere((p) => p.id == parent.id);
      if (pIndex >= 0) {
        targetIndex = pIndex;
      }
    }

    setState(() {
      _isViewingVariants = false;
      _activeVariantsParent = null;
      _currentPage = targetIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
      if (_landscapePageController.hasClients) {
        _landscapePageController.jumpToPage(targetIndex);
      }
    });
  }

  void _onVariantPageChanged(int index) {
    if (_currentVariantIndex == index || _activeVariantsParent == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentVariantIndex = index;
    });

    if (_variantPageController != null &&
        _variantPageController!.hasClients &&
        _variantPageController!.page?.round() != index) {
      _variantPageController!.jumpToPage(index);
    }
    if (_landscapeVariantPageController != null &&
        _landscapeVariantPageController!.hasClients &&
        _landscapeVariantPageController!.page?.round() != index) {
      _landscapeVariantPageController!.jumpToPage(index);
    }

    final parent = _activeVariantsParent!;
    final selectedVariant = parent.variants[index];
    _selectedVariants[parent.id] = selectedVariant.id;

    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(
            themePreset: selectedVariant.id,
            selectedVariants: _selectedVariants,
          ),
          cards,
        );
  }

  String _getActiveVariantSublabel(AppThemePreset parent, String currentPresetId) {
    final effectiveId = _selectedVariants[parent.id] ?? currentPresetId;
    final idx = parent.variants.indexWhere((v) => v.id == effectiveId);
    if (idx >= 0) {
      return '${idx + 1}/${parent.variants.length}';
    }
    return '${parent.variants.length} styles';
  }

  AppThemePreset _resolvePreviewPreset(AppThemePreset parentPreset, String activePresetId) {
    if (parentPreset.hasVariants) {
      if (parentPreset.variants.any((v) => v.id == activePresetId)) {
        return parentPreset.variants.firstWhere((v) => v.id == activePresetId);
      }
      final rememberedId = _selectedVariants[parentPreset.id];
      if (rememberedId != null && parentPreset.variants.any((v) => v.id == rememberedId)) {
        return parentPreset.variants.firstWhere((v) => v.id == rememberedId);
      }
      return parentPreset.variants.first;
    }
    return parentPreset;
  }

  void _cycleThemeMode() {
    HapticFeedback.mediumImpact();
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    // Toggle between dark and light only.
    // The system option is the default, but once someone changes it,
    // it becomes a strict toggle between dark and light only.
    final String nextMode;
    if (settings.themeMode == 'system') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      nextMode = isDark ? 'light' : 'dark';
    } else if (settings.themeMode == 'dark') {
      nextMode = 'light';
    } else {
      nextMode = 'dark';
    }

    ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(themeMode: nextMode),
          cards,
        );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme Mode: ${nextMode[0].toUpperCase()}${nextMode.substring(1)}'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemePickerSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final settings = ref.read(settingsNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
      builder: (sheetCtx) {
        AppThemePreset? selectedParentPreset;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final mq = MediaQuery.of(sheetCtx);
            final sheetIsLandscape = mq.orientation == Orientation.landscape;
            final sheetHeight = mq.size.height;
            final sheetWidth = mq.size.width;
            final crossAxisCount = sheetIsLandscape || sheetWidth >= 520 ? 3 : 2;

            final isViewingSheetVariants = selectedParentPreset != null;
            final activeList = isViewingSheetVariants
                ? selectedParentPreset!.variants
                : _presets;

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  maxHeight: sheetHeight * (sheetIsLandscape ? 0.90 : 0.82),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? context.colors.surfaceCard.withValues(alpha: 0.94)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.2,
                          ),
                          left: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.2,
                          ),
                          right: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag Handle
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.20)
                                        : Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),

                            // Header Bar with Back Button when in variants view
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Row(
                                children: [
                                  if (isViewingSheetVariants)
                                    // Back button to return to main themes (matching main X button style)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          setSheetState(() {
                                            selectedParentPreset = null;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : Colors.black.withValues(alpha: 0.08),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.12)
                                                  : Colors.black.withValues(alpha: 0.08),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.arrow_back_rounded,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    // Palette Icon (matching 40x40 circular geometry)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
                                          border: Border.all(
                                            color: primaryColor.withValues(alpha: isDark ? 0.32 : 0.20),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.palette_rounded,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Title + Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isViewingSheetVariants
                                              ? '${selectedParentPreset!.name} Styles'
                                              : 'Theme Presets',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isViewingSheetVariants
                                              ? '${selectedParentPreset!.variants.length} variations'
                                              : '${_presets.length} distinctive styles',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppTheme.textMuted : AppTheme.slate600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Close (X) button (matching main X button style)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(sheetCtx);
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.12)
                                            : Colors.black.withValues(alpha: 0.08),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.08),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Grid of Cards (AnimatedSwitcher between main themes and variants)
                            Flexible(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: SingleChildScrollView(
                                  key: ValueKey<String>(
                                    isViewingSheetVariants
                                        ? 'variants_${selectedParentPreset!.id}'
                                        : 'main_presets',
                                  ),
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: activeList.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      mainAxisExtent: 114,
                                    ),
                                    itemBuilder: (context, idx) {
                                      final item = activeList[idx];

                                      if (isViewingSheetVariants) {
                                        // Variant Item
                                        final isSelected = settings.themePreset == item.id;
                                        return _ThemePickerCard(
                                          preset: item,
                                          effectivePreset: item,
                                          isSelected: isSelected,
                                          isDark: isDark,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.pop(sheetCtx);
                                            final parent = selectedParentPreset!;
                                            final parentIdx = _presets.indexWhere((p) => p.id == parent.id);
                                            _selectThemeFromSheet(
                                              parent,
                                              item,
                                              parentIdx >= 0 ? parentIdx : _currentPage,
                                            );
                                          },
                                        );
                                      } else {
                                        // Main Preset Item
                                        final isSelected = _currentPage == idx;
                                        final effectivePreset = item.hasVariants
                                            ? _resolvePreviewPreset(item, settings.themePreset)
                                            : item;

                                        return _ThemePickerCard(
                                          preset: item,
                                          effectivePreset: effectivePreset,
                                          isSelected: isSelected,
                                          isDark: isDark,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            if (item.hasVariants) {
                                              // Open variants sub-menu inside the popup
                                              setSheetState(() {
                                                selectedParentPreset = item;
                                              });
                                            } else {
                                              // Standalone preset: dismiss and animate
                                              Navigator.pop(sheetCtx);
                                              _selectThemeFromSheet(
                                                item,
                                                null,
                                                idx,
                                              );
                                            }
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectThemeFromSheet(
    AppThemePreset parentPreset,
    AppThemePreset? selectedVariant,
    int targetIndex,
  ) async {
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    final targetPresetId = selectedVariant?.id ??
        (parentPreset.hasVariants
            ? (_selectedVariants[parentPreset.id] ?? parentPreset.variants.first.id)
            : parentPreset.id);

    if (parentPreset.hasVariants) {
      _selectedVariants[parentPreset.id] = targetPresetId;
    }

    // Stop all shaders immediately from start of transition to the very end
    if (mounted) {
      setState(() {
        _isProgrammaticAnimating = true;
        _isCarouselAnimating = true;
        if (_isViewingVariants) {
          _isViewingVariants = false;
          _activeVariantsParent = null;
        }
      });
    }

    // Update settings to apply the chosen theme/variant
    await ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(
            themePreset: targetPresetId,
            selectedVariants: _selectedVariants,
          ),
          cards,
        );

    // Slide smoothly through the carousel to the selected target screen
    if (_currentPage != targetIndex) {
      final futures = <Future<void>>[];
      if (_pageController.hasClients) {
        futures.add(_pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        ));
      }
      if (_landscapePageController.hasClients) {
        futures.add(_landscapePageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        ));
      }
      await Future.wait(futures);
    }

    // Now that the carousel animation has fully landed and settled, resume shaders!
    if (mounted) {
      setState(() {
        _currentPage = targetIndex;
        _isProgrammaticAnimating = false;
        _isCarouselAnimating = false;
      });
    }
  }

  Color _getThemedAccentColor(AppThemePreset preset, bool isDark) {
    if (isDark) {
      return preset.lineColor;
    }
    final luminance = preset.lineColor.computeLuminance();
    if (luminance > 0.28) {
      final r = preset.lineColor.r;
      final g = preset.lineColor.g;
      final b = preset.lineColor.b;
      final maxC = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
      final minC = [r, g, b].reduce((curr, next) => curr < next ? curr : next);

      // Monochrome or near-grayscale light colors (e.g. Silly Noir, Stealth)
      if ((maxC - minC) < 0.18) {
        return const Color(0xFF0F172A);
      }
      // For bright colorful themes in light mode, ensure good contrast against light surfaces
      final hsl = HSLColor.fromColor(preset.lineColor);
      return hsl.withLightness((hsl.lightness * 0.55).clamp(0.24, 0.38)).toColor();
    }
    return preset.lineColor;
  }

  Widget _buildAnimationToggle(
    AppThemePreset currentPreset,
    AppSettings settings,
    bool isDark,
  ) {
    final activeColor = _getThemedAccentColor(currentPreset, isDark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final cards = ref.read(cardNotifierProvider).cards;
        ref.read(settingsNotifierProvider.notifier).updateSettings(
              settings.copyWith(
                animateBackground: !settings.animateBackground,
              ),
              cards,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: settings.animateBackground
              ? activeColor.withValues(alpha: isDark ? 0.20 : 0.12)
              : (isDark ? Colors.white10 : Colors.black12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: settings.animateBackground
                ? activeColor
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              settings.animateBackground
                  ? Icons.motion_photos_on_rounded
                  : Icons.motion_photos_off_rounded,
              size: 14,
              color: settings.animateBackground
                  ? activeColor
                  : (isDark ? AppTheme.textMuted : AppTheme.slate600),
            ),
            const SizedBox(width: 4),
            Text(
              settings.animateBackground ? 'Animation On' : 'Animation Off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: settings.animateBackground
                    ? activeColor
                    : (isDark ? AppTheme.textMuted : AppTheme.slate600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(AppSettings settings, {required bool isLandscape}) {
    final activeController = _isViewingVariants
        ? (isLandscape ? _landscapeVariantPageController : _variantPageController)
        : (isLandscape ? _landscapePageController : _pageController);

    final carousel = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isViewingVariants && _activeVariantsParent != null
          ? PageView.builder(
              key: PageStorageKey<String>('variants_${_activeVariantsParent!.id}_${isLandscape ? "land" : "port"}'),
              controller: activeController,
              itemCount: _activeVariantsParent!.variants.length,
              onPageChanged: _onVariantPageChanged,
              clipBehavior: isLandscape ? Clip.hardEdge : Clip.none,
              itemBuilder: (context, index) {
                final variant = _activeVariantsParent!.variants[index];
                final isFocused = _currentVariantIndex == index;

                final mockup = _PhoneMockupView(
                  preset: variant,
                  isFocused: isFocused,
                  animate: isFocused &&
                      settings.animateBackground &&
                      _isReadyForShader &&
                      !_isClosing &&
                      !_isCarouselAnimating,
                );

                return AnimatedScale(
                  scale: isFocused ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: isLandscape
                        ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
                        : const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 20.0),
                    child: isLandscape
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: 390 / 844,
                              child: mockup,
                            ),
                          )
                        : mockup,
                  ),
                );
              },
            )
          : PageView.builder(
              key: PageStorageKey<String>('main_themes_carousel_${isLandscape ? "land" : "port"}'),
              controller: activeController,
              itemCount: _presets.length,
              onPageChanged: _onPageChanged,
              clipBehavior: isLandscape ? Clip.hardEdge : Clip.none,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isFocused = _currentPage == index;
                final effectivePreset = preset.hasVariants
                    ? _resolvePreviewPreset(preset, settings.themePreset)
                    : preset;

                final mockup = _PhoneMockupView(
                  preset: effectivePreset,
                  isFocused: isFocused,
                  animate: isFocused &&
                      settings.animateBackground &&
                      _isReadyForShader &&
                      !_isClosing &&
                      !_isCarouselAnimating,
                );

                return AnimatedScale(
                  scale: isFocused ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: isLandscape
                        ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
                        : const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 20.0),
                    child: isLandscape
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: 390 / 844,
                              child: mockup,
                            ),
                          )
                        : mockup,
                  ),
                );
              },
            ),
    );

    final carouselWithScroll = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          if (notification.dragDetails != null &&
              !_isCarouselAnimating &&
              !_isProgrammaticAnimating) {
            setState(() {
              _isCarouselAnimating = true;
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_isCarouselAnimating && !_isProgrammaticAnimating) {
            setState(() {
              _isCarouselAnimating = false;
            });
          }
        }
        return false;
      },
      child: carousel,
    );

    return isLandscape ? ClipRect(child: carouselWithScroll) : carouselWithScroll;
  }

  Widget _buildLandscapeFloatingCloseButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _handleClose(context),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: 0.55),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isViewingVariants ? Icons.arrow_back_rounded : Icons.close_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeRightPanel(
    BuildContext context,
    AppThemePreset currentPreset,
    AppThemePreset focusedMainPreset,
    AppSettings settings,
    bool isDark,
  ) {
    final showVariants = !_isViewingVariants && focusedMainPreset.hasVariants;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.52)
            : Colors.white.withValues(alpha: 0.55),
        border: Border(
          left: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eyebrow / Screen title: "THEME PREVIEW" (or "STYLES")
                  Text(
                    _isViewingVariants ? 'STYLES' : 'THEME PREVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Theme Name
                  Text(
                    currentPreset.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      shadows: AppTheme.textShadowAmbient(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Theme Description / Variant count
                  Text(
                    _isViewingVariants
                        ? 'Style ${_currentVariantIndex + 1} of ${_activeVariantsParent!.variants.length}'
                        : currentPreset.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isViewingVariants
                          ? _getThemedAccentColor(currentPreset, isDark)
                          : (isDark ? AppTheme.textMuted : AppTheme.slate600),
                      fontWeight: _isViewingVariants ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Animation Toggle Pill
                  _buildAnimationToggle(currentPreset, settings, isDark),

                  const SizedBox(height: 16),

                  // Action Buttons: [Mode] and [Theme] with [Variants] sliding straight from the right edge
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      const btnW = 64.0;

                      final modeLeft = showVariants
                          ? (w * 0.17 - btnW / 2)
                          : (w * 0.28 - btnW / 2);
                      final themeLeft = showVariants
                          ? (w * 0.50 - btnW / 2)
                          : (w * 0.72 - btnW / 2);
                      // When hidden, place it beyond the right edge of the panel so it flies in straight from the edge
                      final variantsLeft = showVariants
                          ? (w * 0.83 - btnW / 2)
                          : (w + 40.0);

                      return SizedBox(
                        height: 88,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Mode Button
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                              left: modeLeft,
                              top: 0,
                              child: SizedBox(
                                width: btnW,
                                child: _BottomActionButton(
                                  icon: Icons.contrast_rounded,
                                  label: 'Mode',
                                  sublabel: settings.themeMode[0].toUpperCase() +
                                      settings.themeMode.substring(1),
                                  onTap: _cycleThemeMode,
                                ),
                              ),
                            ),

                            // Theme / Back Button
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                              left: themeLeft,
                              top: 0,
                              child: SizedBox(
                                width: btnW,
                                child: _BottomActionButton(
                                  icon: _isViewingVariants
                                      ? Icons.arrow_back_rounded
                                      : Icons.palette_rounded,
                                  label: _isViewingVariants ? 'All Themes' : 'Theme',
                                  sublabel: _isViewingVariants
                                      ? 'Back'
                                      : '${_currentPage + 1}/${_presets.length}',
                                  onTap: _isViewingVariants
                                      ? _exitVariantsView
                                      : _showThemePickerSheet,
                                ),
                              ),
                            ),

                            // Variants Button - slides straight in from beyond right edge!
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                              left: variantsLeft,
                              top: 0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut,
                                opacity: showVariants ? 1.0 : 0.0,
                                child: SizedBox(
                                  width: btnW,
                                  child: _BottomActionButton(
                                    icon: Icons.style_rounded,
                                    label: 'Variants',
                                    sublabel: _getActiveVariantSublabel(
                                      focusedMainPreset,
                                      settings.themePreset,
                                    ),
                                    onTap: () => _enterVariantsView(focusedMainPreset),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsNotifierProvider);

    final focusedMainPreset = _presets[_currentPage.clamp(0, _presets.length - 1)];
    final currentPreset = _isViewingVariants && _activeVariantsParent != null
        ? _activeVariantsParent!.variants[_currentVariantIndex.clamp(0, _activeVariantsParent!.variants.length - 1)]
        : _resolvePreviewPreset(focusedMainPreset, settings.themePreset);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: !_isViewingVariants,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (mounted && !_isClosing) {
            setState(() {
              _isClosing = true;
              _isReadyForShader = false;
            });
          }
          return;
        }
        if (_isViewingVariants) {
          _exitVariantsView();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
        body: SafeArea(
          child: isLandscape
              ? Stack(
                  children: [
                    Row(
                      children: [
                        // Center Column: Smartphone Mockup Carousel taking full available height
                        Expanded(
                          child: _buildCarousel(settings, isLandscape: true),
                        ),

                        // Right Column: Frosted Dock with Eyebrow, Theme Info, Animation Toggle & Action Buttons
                        _buildLandscapeRightPanel(
                          context,
                          currentPreset,
                          focusedMainPreset,
                          settings,
                          isDark,
                        ),
                      ],
                    ),

                    // Floating frosted close / back button on top-left near edge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildLandscapeFloatingCloseButton(context, isDark),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top Bar: [Back / Close] Button + Screen Title + Animation Toggle Pill
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _handleClose(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                              child: Icon(
                                _isViewingVariants ? Icons.arrow_back_rounded : Icons.close_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            _isViewingVariants ? '${_activeVariantsParent!.name} styles' : 'Theme preview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              shadows: AppTheme.textShadowAmbient(isDark),
                            ),
                          ),
                          const Spacer(),
                          // Animation Toggle Pill
                          _buildAnimationToggle(currentPreset, settings, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Horizontal Carousel of Smartphone Mockups
                    Expanded(
                      child: _buildCarousel(settings, isLandscape: false),
                    ),

                    const SizedBox(height: 6),

                    // Theme Name & Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      child: Column(
                        children: [
                          Text(
                            currentPreset.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              shadows: AppTheme.textShadowAmbient(isDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isViewingVariants
                                ? 'Style ${_currentVariantIndex + 1} of ${_activeVariantsParent!.variants.length}'
                                : currentPreset.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isViewingVariants
                                  ? _getThemedAccentColor(currentPreset, isDark)
                                  : (isDark ? AppTheme.textMuted : AppTheme.slate600),
                              fontWeight: _isViewingVariants ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom Actions Bar: [Mode] and [Theme] with [Variants] sliding straight from screen edge
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          const btnW = 64.0;
                          final showVariants = !_isViewingVariants && focusedMainPreset.hasVariants;

                          final modeLeft = showVariants
                              ? (w * 0.18 - btnW / 2)
                              : (w * 0.32 - btnW / 2);
                          final themeLeft = showVariants
                              ? (w * 0.50 - btnW / 2)
                              : (w * 0.68 - btnW / 2);
                          // When hidden, place it beyond the right edge of the screen so it flies in straight from the edge
                          final variantsLeft = showVariants
                              ? (w * 0.82 - btnW / 2)
                              : (w + 40.0);

                          return SizedBox(
                            height: 88,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Mode Button
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeOutCubic,
                                  left: modeLeft,
                                  top: 0,
                                  child: SizedBox(
                                    width: btnW,
                                    child: _BottomActionButton(
                                      icon: Icons.contrast_rounded,
                                      label: 'Mode',
                                      sublabel: settings.themeMode[0].toUpperCase() +
                                          settings.themeMode.substring(1),
                                      onTap: _cycleThemeMode,
                                    ),
                                  ),
                                ),

                                // Theme / Back Button
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeOutCubic,
                                  left: themeLeft,
                                  top: 0,
                                  child: SizedBox(
                                    width: btnW,
                                    child: _BottomActionButton(
                                      icon: _isViewingVariants
                                          ? Icons.arrow_back_rounded
                                          : Icons.palette_rounded,
                                      label: _isViewingVariants ? 'All Themes' : 'Theme',
                                      sublabel: _isViewingVariants
                                          ? 'Back'
                                          : '${_currentPage + 1}/${_presets.length}',
                                      onTap: _isViewingVariants
                                          ? _exitVariantsView
                                          : _showThemePickerSheet,
                                    ),
                                  ),
                                ),

                                // Variants Button - slides straight in from beyond screen edge!
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.easeOutCubic,
                                  left: variantsLeft,
                                  top: 0,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOut,
                                    opacity: showVariants ? 1.0 : 0.0,
                                    child: SizedBox(
                                      width: btnW,
                                      child: _BottomActionButton(
                                        icon: Icons.style_rounded,
                                        label: 'Variants',
                                        sublabel: _getActiveVariantSublabel(
                                          focusedMainPreset,
                                          settings.themePreset,
                                        ),
                                        onTap: () => _enterVariantsView(focusedMainPreset),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A simulated smartphone viewport preview with rounded corners, top camera notch,
/// and CardMinder's actual, full [HomeView] rendered directly inside.
class _PhoneMockupView extends StatelessWidget {
  final AppThemePreset preset;
  final bool isFocused;
  final bool animate;

  const _PhoneMockupView({
    required this.preset,
    required this.isFocused,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final outerRadius = isLandscape ? 20.0 : 36.0;
    final innerRadius = isLandscape ? 18.0 : 34.0;
    final borderWidth = isLandscape ? (isFocused ? 1.8 : 1.4) : (isFocused ? 2.0 : 1.5);
    final statusBarHeight = isLandscape ? 40.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        color: preset.bgColor,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: isFocused
              ? preset.lineColor.withValues(alpha: 0.55)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.12)),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
            blurRadius: isLandscape ? (isFocused ? 16.0 : 10.0) : (isFocused ? 16.0 : 10.0),
            offset: isLandscape ? const Offset(0, 6) : const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final frameWidth = constraints.maxWidth;
            final frameHeight = constraints.maxHeight;
            const virtualWidth = 390.0;
            final virtualHeight = virtualWidth * (frameHeight / frameWidth);

            return FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: virtualWidth,
                height: virtualHeight,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(virtualWidth, virtualHeight),
                    padding: EdgeInsets.only(top: statusBarHeight, bottom: 0),
                    viewPadding: EdgeInsets.only(top: statusBarHeight, bottom: 0),
                  ),
                  child: IgnorePointer(
                    ignoring: true,
                    child: Stack(
                      children: [
                        // The actual real-world CardMinder Home screen
                        Positioned.fill(
                          child: HomeView(
                            presetOverride: preset,
                            animateOverride: animate,
                            isInteractive: false,
                            showBottomNavBar: true,
                            isPreview: true,
                          ),
                        ),

                        // Realistic Smartphone Status Bar Overlay (Camera hole punch, Time, Wifi/Battery)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: statusBarHeight,
                          child: _PhoneStatusBar(
                            isDarkText: preset.id == 'classic' && !isDark,
                            isLandscape: isLandscape,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Simulated smartphone status bar (Android hole punch camera, live time synced to user clock, battery/wifi)
class _PhoneStatusBar extends StatefulWidget {
  final bool isDarkText;
  final bool isLandscape;

  const _PhoneStatusBar({
    this.isDarkText = false,
    this.isLandscape = false,
  });

  @override
  State<_PhoneStatusBar> createState() => _PhoneStatusBarState();
}

class _PhoneStatusBarState extends State<_PhoneStatusBar> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newNow = DateTime.now();
      if (newNow.minute != _now.minute || newNow.hour != _now.hour) {
        if (mounted) {
          setState(() {
            _now = newNow;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formattedTime(BuildContext context) {
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    if (use24) {
      final hour = _now.hour.toString().padLeft(2, '0');
      final minute = _now.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
      final minute = _now.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = widget.isDarkText
        ? const Color(0xFF0F172A)
        : Colors.white;
    final horizontalPadding = widget.isLandscape ? 34.0 : 26.0;
    final barHeight = widget.isLandscape ? 40.0 : 36.0;

    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          // Time on left & status icons on right
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formattedTime(context),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: contentColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 15,
                        color: contentColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.wifi_rounded,
                        size: 15,
                        color: contentColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.battery_full_rounded,
                        size: 17,
                        color: contentColor.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Android-Style Hole Punch Camera (precisely centered)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF05070B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDarkText
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular bottom action button with label and state badge (Mode / Theme / Variants)
class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF1F2533)
                  : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual card representing a theme preset in the theme picker bottom sheet.
class _ThemePickerCard extends StatelessWidget {
  final AppThemePreset preset;
  final AppThemePreset effectivePreset;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemePickerCard({
    required this.preset,
    required this.effectivePreset,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? effectivePreset.lineColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.08));

    final cardBg = isSelected
        ? effectivePreset.lineColor.withValues(alpha: isDark ? 0.14 : 0.08)
        : (isDark ? const Color(0xFF1B2232) : const Color(0xFFF1F5F9));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectivePreset.lineColor.withValues(alpha: isDark ? 0.28 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon + Swatch capsule + Selection check / Variant badge
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: effectivePreset.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: effectivePreset.lineColor.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        effectivePreset.icon,
                        size: 16,
                        color: effectivePreset.lineColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mini Color Swatch Capsule
                  Container(
                    height: 12,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          effectivePreset.bgColor,
                          effectivePreset.lineColor,
                          effectivePreset.accentColor,
                        ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Selected checkmark or Variant indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: effectivePreset.lineColor,
                    )
                  else if (preset.hasVariants)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${preset.variants.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textMuted : AppTheme.slate600,
                        ),
                      ),
                    ),
                ],
              ),

              // Bottom Area: Title + Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.hasVariants
                        ? '${preset.variants.length} styles'
                        : (effectivePreset.isDark ? 'Dark theme' : 'Light theme'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? effectivePreset.lineColor
                          : (isDark ? AppTheme.textMuted : AppTheme.slate600),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
