import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/credit_card.dart';
import '../../providers/card_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/add_edit_card_screen.dart';
import '../../screens/card_details_screen.dart';
import '../../screens/notification_logs_screen.dart';
import '../../services/notification_log_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';
import '../card_tile.dart';
import '../credit_card_view.dart';
import '../delete_confirmation_dialog.dart';
import '../theme/shader_background_view.dart';
import 'edit_user_name_dialog.dart';
import 'home_bottom_nav_bar.dart';
import 'home_empty_state.dart';

/// Reusable Home View displaying CardMinder's actual home screen interface:
/// animated GLSL shader background, dynamic ambient backdrop tint, user header,
/// swipeable credit card carousel, indicator dots, All Cards section, and card list.
///
/// Used both for the live [HomeScreen] and inside [ThemePreviewScreen] for a 100% faithful preview.
class HomeView extends ConsumerStatefulWidget {
  final AppThemePreset? presetOverride;
  final bool? animateOverride;
  final bool isInteractive;
  final bool showBottomNavBar;
  final bool isPreview;
  final ScrollController? scrollController;
  final PageController? pageController;
  final ValueChanged<String>? onCardAdded;

  const HomeView({
    super.key,
    this.presetOverride,
    this.animateOverride,
    this.isInteractive = true,
    this.showBottomNavBar = false,
    this.isPreview = false,
    this.scrollController,
    this.pageController,
    this.onCardAdded,
  });

  /// Sample cards used for rich previews when no cards have been added yet
  static final List<CreditCard> samplePreviewCards = [
    CreditCard(
      id: 'preview_sample_1',
      cardName: 'Sapphire Preferred',
      lastFourDigits: '4321',
      lastTransactionDate: DateTime.now().subtract(const Duration(days: 3)),
      colorIndex: 0,
      cardType: 'Credit Card',
      network: 'Visa',
      expiryMonth: '12',
      expiryYear: '28',
    ),
    CreditCard(
      id: 'preview_sample_2',
      cardName: 'Gold Reserve',
      lastFourDigits: '8888',
      lastTransactionDate: DateTime.now().subtract(const Duration(days: 14)),
      colorIndex: 1,
      cardType: 'Charge Card',
      network: 'Amex',
      expiryMonth: '08',
      expiryYear: '27',
    ),
  ];

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _currentPage = 0;
  PageController? _internalPageController;
  ScrollController? _internalScrollController;

  PageController get _pageController =>
      widget.pageController ??
      (_internalPageController ??= PageController(initialPage: _currentPage));

  ScrollController get _scrollController =>
      widget.scrollController ??
      (_internalScrollController ??= ScrollController());

  @override
  void dispose() {
    _internalPageController?.dispose();
    _internalScrollController?.dispose();
    super.dispose();
  }

  void _syncSelectedCard(String? closedCardId) {
    if (closedCardId == null || !mounted) return;
    final currentCards = ref.read(cardNotifierProvider).filteredCards;
    final targetIdx = currentCards.indexWhere((c) => c.id == closedCardId);
    if (targetIdx != -1) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0.0);
      }
      setState(() => _currentPage = targetIdx);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIdx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // In interactive mode, dock newly added card into view
    if (widget.isInteractive) {
      ref.listen<CardState>(cardNotifierProvider, (previous, next) {
        if (previous != null && next.cards.length > previous.cards.length) {
          if (_scrollController.hasClients && _scrollController.offset > 0) {
            _scrollController.jumpTo(0.0);
          }
          final previousIds = previous.cards.map((c) => c.id).toSet();
          final addedCards =
              next.cards.where((c) => !previousIds.contains(c.id));
          if (addedCards.isNotEmpty) {
            final addedCard = addedCards.first;
            final targetIndex =
                next.filteredCards.indexWhere((c) => c.id == addedCard.id);
            if (targetIndex != -1) {
              setState(() {
                _currentPage = targetIndex;
              });
              if (_pageController.hasClients) {
                _pageController.jumpToPage(targetIndex);
              }
            }
          }
        }
      });
    }

    final state = ref.watch(cardNotifierProvider);
    final rawCards = state.filteredCards;
    final cards = (widget.isPreview && rawCards.isEmpty)
        ? HomeView.samplePreviewCards
        : rawCards;

    final settings = ref.watch(settingsNotifierProvider);
    final unreadLogsCount =
        ref.watch(notificationLogNotifierProvider.notifier).unreadCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCardColor = cards.isNotEmpty
        ? AppTheme.getCardColors(
            cards[_currentPage.clamp(0, cards.length - 1)].colorIndex).first
        : (isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy);

    final currentPreset = widget.presetOverride ??
        ThemePresets.getById(settings.themePreset);
    final effectiveAnimate =
        widget.animateOverride ?? settings.animateBackground;

    final content = Stack(
      children: [
        // 1. Hardware-Accelerated GLSL Fragment Shader Background
        Positioned.fill(
          child: IgnorePointer(
            child: ShaderBackgroundView(
              preset: currentPreset,
              animate: effectiveAnimate,
              opacity: isDark ? 0.75 : 0.35,
            ),
          ),
        ),

        // 2. Full-bleed Dynamic Ambient Backdrop Tint (Seamless edge-to-edge)
        if (cards.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 480,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      activeCardColor.withValues(alpha: isDark ? 0.20 : 0.10),
                      activeCardColor.withValues(alpha: isDark ? 0.24 : 0.12),
                      activeCardColor.withValues(alpha: isDark ? 0.08 : 0.04),
                      activeCardColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.40, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // 3. Main Screen Content inside SafeArea
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Bar Header (Welcome back, <userName> & Notification Bell)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Name Header
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.isInteractive
                            ? () => EditUserNameDialog.show(
                                  context: context,
                                  currentName: settings.userName,
                                  onSave: (newName) {
                                    ref
                                        .read(settingsNotifierProvider.notifier)
                                        .updateSettings(
                                            settings.copyWith(
                                                userName: newName),
                                            cards.cast());
                                  },
                                )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.slate300
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                                shadows: AppTheme.textShadowSubtle(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                shadows: AppTheme.textShadowAmbient(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Dynamic Notification Bell Button
                    GestureDetector(
                      onTap: widget.isInteractive
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationLogsScreen(),
                                ),
                              );
                            }
                          : null,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                          .withValues(alpha: 0.55)
                                      : Colors.white.withValues(alpha: 0.70),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.accentRose
                                            .withValues(alpha: 0.40)
                                        : AppTheme.accentRose
                                            .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppTheme.accentRose,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          if (unreadLogsCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRose,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadLogsCount',
                                  style: const TextStyle(
                                    color: AppTheme.surfaceWhite,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
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

              // Content Area: Empty state or Credit Card Carousel & Cards List
              Expanded(
                child: cards.isEmpty
                    ? HomeEmptyState(
                        settings: settings,
                        onCardAdded: widget.onCardAdded,
                      )
                    : NotificationListener<OverscrollIndicatorNotification>(
                        onNotification: (overscroll) {
                          overscroll.disallowIndicator();
                          return true;
                        },
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            overscroll: false,
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: widget.isInteractive
                                ? const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  )
                                : const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                            // Top Credit Card Carousel
                            SizedBox(
                              height: 195,
                              child: PageView.builder(
                                controller: _pageController,
                                clipBehavior: Clip.none,
                                physics: widget.isInteractive
                                    ? null
                                    : const NeverScrollableScrollPhysics(),
                                itemCount: cards.length,
                                onPageChanged: (index) {
                                  setState(() => _currentPage = index);
                                  if (widget.isInteractive) {
                                    HapticFeedback.selectionClick();
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final card = cards[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: CreditCardView(
                                      card: card,
                                      heroTag: widget.isPreview
                                          ? null
                                          : 'card-hero-${card.id}',
                                      isInteractive: widget.isInteractive,
                                      enableTilt: widget.isInteractive,
                                      onTap: widget.isInteractive
                                          ? () async {
                                              final closedCardId =
                                                  await Navigator.push<String?>(
                                                context,
                                                slideUpRoute(
                                                  CardDetailsScreen(card: card),
                                                ),
                                              );
                                              _syncSelectedCard(closedCardId);
                                            }
                                          : null,
                                      onLongPress: widget.isInteractive
                                          ? () {
                                              Navigator.push(
                                                context,
                                                slideUpRoute(
                                                  AddEditCardScreen(
                                                      cardToEdit: card),
                                                ),
                                              );
                                            }
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Page Indicator Dots (. . -)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(cards.length, (index) {
                                final isSelected = _currentPage == index;
                                final activeDotColor =
                                    context.colors.buttonPrimaryBg;
                                final inactiveDotColor = isDark
                                    ? Colors.white.withValues(alpha: 0.32)
                                    : Colors.black.withValues(alpha: 0.22);
                                final borderColor = isSelected
                                    ? activeDotColor
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : Colors.black.withValues(alpha: 0.10));

                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: isSelected ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? activeDotColor
                                        : inactiveDotColor,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 0.5,
                                    ),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 24),

                            // All Cards Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'All Cards',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          shadows:
                                              AppTheme.textShadowAmbient(isDark),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E293B)
                                                      .withValues(alpha: 0.55)
                                                  : Colors.white
                                                      .withValues(alpha: 0.70),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppTheme.primaryAccentDark
                                                        .withValues(alpha: 0.35)
                                                    : AppTheme.primaryNavy
                                                        .withValues(alpha: 0.15),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              '${cards.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? AppTheme.primaryAccentDark
                                                    : AppTheme.primaryNavy,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: widget.isInteractive
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            ref
                                                .read(cardNotifierProvider
                                                    .notifier)
                                                .toggleSortMode();
                                          }
                                        : null,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(
                                            sigmaX: 8, sigmaY: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                    .withValues(alpha: 0.55)
                                                : Colors.white
                                                    .withValues(alpha: 0.70),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppTheme.primaryAccentDark
                                                      .withValues(alpha: 0.35)
                                                  : AppTheme.primaryNavy
                                                      .withValues(alpha: 0.18),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                state.sortMode ==
                                                        SortMode.urgency
                                                    ? Icons.bolt_rounded
                                                    : Icons
                                                        .drag_indicator_rounded,
                                                size: 14,
                                                color: isDark
                                                    ? AppTheme.primaryAccentDark
                                                    : AppTheme.primaryNavy,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                state.sortMode ==
                                                        SortMode.urgency
                                                    ? 'Sorted by urgency'
                                                    : 'User Defined',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? AppTheme.primaryAccentDark
                                                      : AppTheme.primaryNavy,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Cards List inside Frosted Glass Grouped Container
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF161B26)
                                              .withValues(alpha: 0.65)
                                          : Colors.white
                                              .withValues(alpha: 0.70),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.10)
                                            : Colors.black
                                                .withValues(alpha: 0.06),
                                        width: 1,
                                      ),
                                    ),
                                    child: widget.isInteractive
                                        ? ReorderableListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: cards.length,
                                            padding: EdgeInsets.zero,
                                            proxyDecorator:
                                                (child, index, animation) {
                                              return AnimatedBuilder(
                                                animation: animation,
                                                builder: (context, _) {
                                                  return Material(
                                                    elevation: 6,
                                                    color: isDark
                                                        ? const Color(0xFF1E293B)
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    child: child,
                                                  );
                                                },
                                              );
                                            },
                                            onReorderStart: (_) {
                                              HapticFeedback.mediumImpact();
                                            },
                                            onReorderItem:
                                                (oldIndex, newIndex) {
                                              HapticFeedback.lightImpact();
                                              ref
                                                  .read(cardNotifierProvider
                                                      .notifier)
                                                  .reorderCards(
                                                      oldIndex, newIndex);
                                            },
                                            itemBuilder: (context, index) {
                                              final card = cards[index];
                                              return SwipeableCardTile(
                                                key: ValueKey(card.id),
                                                card: card,
                                                showDivider:
                                                    index < cards.length - 1,
                                                onTap: () async {
                                                  final closedCardId =
                                                      await Navigator.push<
                                                          String?>(
                                                    context,
                                                    zoomFromCenterRoute(
                                                      CardDetailsScreen(
                                                          card: card),
                                                    ),
                                                  );
                                                  _syncSelectedCard(
                                                      closedCardId);
                                                },
                                                onEdit: () {
                                                  Navigator.push(
                                                    context,
                                                    slideUpRoute(
                                                      AddEditCardScreen(
                                                          cardToEdit: card),
                                                    ),
                                                  );
                                                },
                                                onDeleteConfirm: () async {
                                                  final confirm =
                                                      await showDeleteConfirmationDialog(
                                                    context: context,
                                                    cardName: card.cardName,
                                                  );
                                                  if (confirm == true) {
                                                    ref
                                                        .read(
                                                            cardNotifierProvider
                                                                .notifier)
                                                        .deleteCard(card.id);
                                                    return true;
                                                  }
                                                  return false;
                                                },
                                              );
                                            },
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: cards.length,
                                            padding: EdgeInsets.zero,
                                            itemBuilder: (context, index) {
                                              final card = cards[index];
                                              return SwipeableCardTile(
                                                key: ValueKey(card.id),
                                                card: card,
                                                showDivider:
                                                    index < cards.length - 1,
                                                onTap: () {},
                                                onEdit: () {},
                                                onDeleteConfirm: () async =>
                                                    false,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.showBottomNavBar) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: content,
        bottomNavigationBar: HomeBottomNavBar(
          selectedTab: 0,
          onTabSelected: (_) {},
          onHomeReselected: () {},
        ),
      );
    }

    return content;
  }
}
