import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/card_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/home_view.dart';

/// Revolut-inspired full-screen Theme Preview experience with animated GLSL shaders,
/// horizontal smartphone mockup carousel, dynamic edge-sliding Variants button, and quick Mode controls.
class ThemePreviewScreen extends ConsumerStatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  ConsumerState<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends ConsumerState<ThemePreviewScreen> {
  late PageController _pageController;
  PageController? _variantPageController;
  late int _currentPage;
  int _currentVariantIndex = 0;
  bool _isViewingVariants = false;
  AppThemePreset? _activeVariantsParent;

  final List<AppThemePreset> _presets = ThemePresets.all;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    final parent = ThemePresets.findParentOrSelf(settings.themePreset);
    final initialIndex = _presets.indexWhere((p) => p.id == parent.id);
    _currentPage = initialIndex >= 0 ? initialIndex : 0;

    _pageController = PageController(
      viewportFraction: 0.72,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _variantPageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isViewingVariants) return;
    if (_currentPage == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = index;
    });

    final selectedPreset = _presets[index];
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    String targetId = selectedPreset.id;
    if (selectedPreset.hasVariants) {
      final isAlreadyVariant = selectedPreset.variants.any((v) => v.id == settings.themePreset);
      targetId = isAlreadyVariant ? settings.themePreset : selectedPreset.variants.first.id;
    }

    ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(themePreset: targetId),
          cards,
        );
  }

  void _enterVariantsView(AppThemePreset parent) {
    HapticFeedback.mediumImpact();
    final settings = ref.read(settingsNotifierProvider);
    final variantIndex = parent.variants.indexWhere((v) => v.id == settings.themePreset);
    final idx = variantIndex >= 0 ? variantIndex : 0;

    _variantPageController?.dispose();
    _variantPageController = PageController(
      viewportFraction: 0.72,
      initialPage: idx,
    );

    setState(() {
      _isViewingVariants = true;
      _activeVariantsParent = parent;
      _currentVariantIndex = idx;
    });

    final selectedVariant = parent.variants[idx];
    if (selectedVariant.id != settings.themePreset) {
      final cards = ref.read(cardNotifierProvider).cards;
      ref.read(settingsNotifierProvider.notifier).updateSettings(
            settings.copyWith(themePreset: selectedVariant.id),
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
    });
  }

  void _onVariantPageChanged(int index) {
    if (_currentVariantIndex == index || _activeVariantsParent == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentVariantIndex = index;
    });

    final selectedVariant = _activeVariantsParent!.variants[index];
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    ref.read(settingsNotifierProvider.notifier).updateSettings(
          settings.copyWith(themePreset: selectedVariant.id),
          cards,
        );
  }

  String _getActiveVariantSublabel(AppThemePreset parent, String currentPresetId) {
    final idx = parent.variants.indexWhere((v) => v.id == currentPresetId);
    if (idx >= 0) {
      return '${idx + 1}/${parent.variants.length}';
    }
    return '${parent.variants.length} styles';
  }

  AppThemePreset _resolvePreviewPreset(AppThemePreset parentPreset, String activePresetId) {
    if (parentPreset.hasVariants) {
      return parentPreset.variants.firstWhere(
        (v) => v.id == activePresetId,
        orElse: () => parentPreset.variants.first,
      );
    }
    return parentPreset;
  }

  void _cycleThemeMode() {
    HapticFeedback.mediumImpact();
    final settings = ref.read(settingsNotifierProvider);
    final cards = ref.read(cardNotifierProvider).cards;

    // Cycle: system -> dark -> light -> system
    String nextMode;
    switch (settings.themeMode) {
      case 'system':
        nextMode = 'dark';
        break;
      case 'dark':
        nextMode = 'light';
        break;
      case 'light':
      default:
        nextMode = 'system';
        break;
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
    final settings = ref.read(settingsNotifierProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141824) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Theme Preset',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _presets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final preset = _presets[idx];
                      final isSelected = _currentPage == idx;
                      final effectivePreset = preset.hasVariants
                          ? _resolvePreviewPreset(preset, settings.themePreset)
                          : preset;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: isSelected
                            ? effectivePreset.lineColor.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F5F9)),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: effectivePreset.bgColor,
                            border: Border.all(
                              color: effectivePreset.lineColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              effectivePreset.icon,
                              size: 18,
                              color: effectivePreset.lineColor,
                            ),
                          ),
                        ),
                        title: Text(
                          effectivePreset.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          preset.hasVariants
                              ? '${effectivePreset.description} • ${preset.variants.length} styles'
                              : effectivePreset.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: effectivePreset.lineColor)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return PopScope(
      canPop: !_isViewingVariants,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isViewingVariants) {
          _exitVariantsView();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: [Back / Close] Button + Screen Title + Animation Toggle Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isViewingVariants) {
                          _exitVariantsView();
                        } else {
                          Navigator.pop(context);
                        }
                      },
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
                    GestureDetector(
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
                              ? currentPreset.lineColor.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: settings.animateBackground
                                ? currentPreset.lineColor
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
                                  ? currentPreset.lineColor
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              settings.animateBackground ? 'Animation On' : 'Animation Off',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: settings.animateBackground
                                  ? currentPreset.lineColor
                                  : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Horizontal Carousel of Smartphone Mockups
              Expanded(
                child: AnimatedSwitcher(
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
                          key: PageStorageKey<String>('variants_${_activeVariantsParent!.id}'),
                          controller: _variantPageController,
                          itemCount: _activeVariantsParent!.variants.length,
                          onPageChanged: _onVariantPageChanged,
                          clipBehavior: Clip.none,
                          itemBuilder: (context, index) {
                            final variant = _activeVariantsParent!.variants[index];
                            final isFocused = _currentVariantIndex == index;

                            return AnimatedScale(
                              scale: isFocused ? 1.0 : 0.92,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                child: _PhoneMockupView(
                                  preset: variant,
                                  isFocused: isFocused,
                                  animate: isFocused && settings.animateBackground,
                                ),
                              ),
                            );
                          },
                        )
                      : PageView.builder(
                          key: const PageStorageKey<String>('main_themes_carousel_key'),
                          controller: _pageController,
                          itemCount: _presets.length,
                          onPageChanged: _onPageChanged,
                          clipBehavior: Clip.none,
                          itemBuilder: (context, index) {
                            final preset = _presets[index];
                            final isFocused = _currentPage == index;
                            final effectivePreset = preset.hasVariants
                                ? _resolvePreviewPreset(preset, settings.themePreset)
                                : preset;

                            return AnimatedScale(
                              scale: isFocused ? 1.0 : 0.92,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                child: _PhoneMockupView(
                                  preset: effectivePreset,
                                  isFocused: isFocused,
                                  animate: isFocused && settings.animateBackground,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Theme Name & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
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
                          ? '${_activeVariantsParent!.name} • Style ${_currentVariantIndex + 1} of ${_activeVariantsParent!.variants.length}'
                          : (focusedMainPreset.hasVariants
                              ? '${currentPreset.description} (${focusedMainPreset.variants.length} color styles)'
                              : currentPreset.description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isViewingVariants ? currentPreset.lineColor : AppTheme.textMuted,
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isFocused
              ? preset.lineColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: isFocused ? 24 : 14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
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
                    padding: const EdgeInsets.only(top: 44, bottom: 20),
                    viewPadding: const EdgeInsets.only(top: 44, bottom: 20),
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

                        // Realistic Smartphone Status Bar Overlay (Dynamic Island notch, Time, Wifi/Battery)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 44,
                          child: _PhoneStatusBar(
                            isDarkText: preset.id == 'classic' && !isDark,
                          ),
                        ),

                        // Smartphone Home Indicator Bar at the bottom
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 4,
                              decoration: BoxDecoration(
                                color: (preset.id == 'classic' && !isDark)
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
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

/// Simulated smartphone status bar (Dynamic Island, live time synced to user clock, battery/wifi)
class _PhoneStatusBar extends StatefulWidget {
  final bool isDarkText;

  const _PhoneStatusBar({this.isDarkText = false});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formattedTime(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: contentColor,
              letterSpacing: -0.2,
            ),
          ),
          Container(
            width: 110,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: widget.isDarkText
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: 16,
                color: contentColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.wifi_rounded,
                size: 16,
                color: contentColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.battery_full_rounded,
                size: 18,
                color: contentColor.withValues(alpha: 0.9),
              ),
            ],
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
