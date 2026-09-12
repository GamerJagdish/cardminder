import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_log_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/card_tile.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/home/edit_user_name_dialog.dart';
import '../widgets/home/home_bottom_nav_bar.dart';
import '../widgets/home/home_empty_state.dart';
import 'add_edit_card_screen.dart';
import 'card_details_screen.dart';
import 'notification_logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentPage = 0;
  int _selectedTab = 0;
  late PageController _pageController;
  late ScrollController _homeScrollController;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
    );
    _homeScrollController = ScrollController();
    _initWidgetLaunchHandling();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cards = ref.read(cardNotifierProvider).cards;
      ref
          .read(notificationLogNotifierProvider.notifier)
          .updateLogsForCards(cards);

      try {
        await WidgetService.updateHomeWidget(cards);
        await NotificationService.requestPermissions();
        await NotificationService.syncCardNotifications(cards);
        await UpdateService.cleanupOldApks();
      } catch (_) {}
    });
  }

  void _initWidgetLaunchHandling() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleWidgetLaunchUri(uri);
        });
      }
    });

    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
      _handleWidgetLaunchUri(uri);
    });
  }

  void _handleWidgetLaunchUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final cardId = uri.queryParameters['id'] ??
        (uri.host == 'card' && uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null);
    final cardName = uri.queryParameters['name'];
    final cardDigits = uri.queryParameters['digits'];

    final cards = ref.read(cardNotifierProvider).cards;
    CreditCard? targetCard;
    if (cardId != null && cardId.isNotEmpty) {
      targetCard = cards.where((c) => c.id == cardId).firstOrNull;
    }
    if (targetCard == null && (cardDigits != null || cardName != null)) {
      targetCard = cards.where((c) {
        if (cardDigits != null &&
            cardDigits.isNotEmpty &&
            c.lastFourDigits == cardDigits) {
          return true;
        }
        if (cardName != null &&
            cardName.isNotEmpty &&
            c.cardName.toLowerCase() == cardName.toLowerCase()) {
          return true;
        }
        return false;
      }).firstOrNull;
    }

    if (targetCard != null) {
      _syncSelectedCard(targetCard.id);
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.push<String?>(
        context,
        slideUpRoute(
          CardDetailsScreen(card: targetCard),
        ),
      ).then((closedCardId) {
        _syncSelectedCard(closedCardId);
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    _pageController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _syncSelectedCard(String? closedCardId) {
    if (closedCardId == null || !mounted) return;
    final currentCards = ref.read(cardNotifierProvider).filteredCards;
    final targetIdx = currentCards.indexWhere((c) => c.id == closedCardId);
    if (targetIdx != -1) {
      if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
        _homeScrollController.jumpTo(0.0);
      }
      setState(() => _currentPage = targetIdx);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIdx);
      }
    }
  }

  void _onCardAdded(String cardId) {
    if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
      _homeScrollController.jumpTo(0.0);
    }
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Prime the carousel and scroll position to the newly added card so the Hero animation docks into place
    ref.listen<CardState>(cardNotifierProvider, (previous, next) {
      if (previous != null && next.cards.length > previous.cards.length) {
        if (_homeScrollController.hasClients &&
            _homeScrollController.offset > 0) {
          _homeScrollController.jumpTo(0.0);
        }
        final previousIds = previous.cards.map((c) => c.id).toSet();
        final addedCards = next.cards.where((c) => !previousIds.contains(c.id));
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

    final state = ref.watch(cardNotifierProvider);
    final cards = state.filteredCards;
    final settings = ref.watch(settingsNotifierProvider);
    final unreadLogsCount =
        ref.watch(notificationLogNotifierProvider.notifier).unreadCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCardColor = cards.isNotEmpty
        ? AppTheme.getCardColors(
            cards[_currentPage.clamp(0, cards.length - 1)].colorIndex).first
        : (isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Full-bleed Dynamic Ambient Backdrop Tint (Seamless edge-to-edge from status bar through header & cards)
          if (cards.isNotEmpty && _selectedTab == 0)
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
                        activeCardColor.withValues(
                            alpha: isDark ? 0.20 : 0.10),
                        activeCardColor.withValues(
                            alpha: isDark ? 0.24 : 0.12),
                        activeCardColor.withValues(
                            alpha: isDark ? 0.08 : 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.40, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // Main Screen Content inside SafeArea
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedTab,
              children: [
                Column(
                  children: [
                  // Top App Bar Header (Welcome back, <userName> & Notification Bell)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tappable User Name Header
                        Expanded(
                          child: GestureDetector(
                            onTap: () => EditUserNameDialog.show(
                              context: context,
                              currentName: settings.userName,
                              onSave: (newName) {
                                ref
                                    .read(settingsNotifierProvider.notifier)
                                    .updateSettings(
                                        settings.copyWith(userName: newName),
                                        cards.cast());
                              },
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Real Dynamic Notification Bell Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationLogsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.accentRose.withValues(alpha: 0.2)
                                      : const Color(0xFFFEE2E2)
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.accentRose.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppTheme.accentRose,
                                  size: 22,
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
                                        color: Colors.white,
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

                  Expanded(
                    child: cards.isEmpty
                        ? HomeEmptyState(
                            settings: settings,
                            onCardAdded: _onCardAdded,
                          )
                        : SingleChildScrollView(
                            controller: _homeScrollController,
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
                                    itemCount: cards.length,
                                    onPageChanged: (index) {
                                      setState(() => _currentPage = index);
                                      HapticFeedback.selectionClick();
                                    },
                                    itemBuilder: (context, index) {
                                      final card = cards[index];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: CreditCardView(
                                          card: card,
                                          heroTag: 'card-hero-${card.id}',
                                          onTap: () async {
                                            final closedCardId =
                                                await Navigator.push<String?>(
                                              context,
                                              slideUpRoute(
                                                CardDetailsScreen(card: card),
                                              ),
                                            );
                                            _syncSelectedCard(closedCardId);
                                          },
                                          onLongPress: () {
                                            Navigator.push(
                                              context,
                                              slideUpRoute(
                                                AddEditCardScreen(
                                                    cardToEdit: card),
                                              ),
                                            );
                                          },
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
                                    final activeDotColor = isDark
                                        ? AppTheme.primaryAccentDark
                                        : AppTheme.primaryNavy;
                                    final inactiveDotColor = isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1);

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
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppTheme.primaryAccentDark
                                                      .withValues(alpha: 0.18)
                                                  : AppTheme.primaryNavy
                                                      .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          ref
                                              .read(cardNotifierProvider
                                                  .notifier)
                                              .toggleSortMode();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppTheme.primaryAccentDark
                                                    .withValues(alpha: 0.15)
                                                : AppTheme.primaryNavy
                                                    .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppTheme.primaryAccentDark
                                                      .withValues(alpha: 0.3)
                                                  : AppTheme.primaryNavy
                                                      .withValues(alpha: 0.15),
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
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Cards List with Drag-and-Drop Reordering
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cards.length,
                                  padding: const EdgeInsets.only(bottom: 20),
                                  onReorderStart: (_) {
                                    HapticFeedback.mediumImpact();
                                  },
                                  onReorderItem: (oldIndex, newIndex) {
                                    HapticFeedback.lightImpact();
                                    ref
                                        .read(cardNotifierProvider.notifier)
                                        .reorderCards(oldIndex, newIndex);
                                  },
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    return SwipeableCardTile(
                                      key: ValueKey(card.id),
                                      card: card,
                                      onTap: () async {
                                        final closedCardId =
                                            await Navigator.push<String?>(
                                          context,
                                          zoomFromCenterRoute(
                                            CardDetailsScreen(card: card),
                                          ),
                                        );
                                        _syncSelectedCard(closedCardId);
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
                                              .read(cardNotifierProvider
                                                  .notifier)
                                              .deleteCard(card.id);
                                          return true;
                                        }
                                        return false;
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                    ),
                  ],
                ),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),

      // Custom Floating Bottom Navigation Bar (Mathematically Centered 3-Column Grid)
      bottomNavigationBar: HomeBottomNavBar(
        selectedTab: _selectedTab,
        onTabSelected: (tab) => setState(() => _selectedTab = tab),
        onHomeReselected: () {
          if (_homeScrollController.hasClients &&
              _homeScrollController.offset > 0) {
            _homeScrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        },
        onCardAdded: _onCardAdded,
      ),
    );
  }
}
