import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_log_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/card_tile.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/delete_confirmation_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final cards = ref.read(cardNotifierProvider).cards;
      ref
          .read(notificationLogNotifierProvider.notifier)
          .updateLogsForCards(cards);
    });
  }

  void _showEditNameDialog(
      BuildContext context, String currentName, List cards) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Your Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 25,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    final settings = ref.read(settingsNotifierProvider);
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .updateSettings(
                            settings.copyWith(userName: newName),
                            cards.cast());
                  }
                  Navigator.pop(dialogCtx);
                },
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  counterText: '',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryAccentDark
                            : AppTheme.primaryNavy,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          final settings = ref.read(settingsNotifierProvider);
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .updateSettings(
                                  settings.copyWith(userName: newName),
                                  cards.cast());
                        }
                        Navigator.pop(dialogCtx);
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardNotifierProvider);
    final cards = state.filteredCards;
    final settings = ref.watch(settingsNotifierProvider);
    final unreadLogsCount =
        ref.watch(notificationLogNotifierProvider.notifier).unreadCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _selectedTab == 1
            ? const SettingsScreen()
            : Column(
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
                            onTap: () => _showEditNameDialog(
                                context, settings.userName, cards),
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
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),

                                // Top Credit Card Carousel
                                SizedBox(
                                  height: 200,
                                  child: PageView.builder(
                                    itemCount: cards.length,
                                    onPageChanged: (index) {
                                      setState(() => _currentPage = index);
                                    },
                                    itemBuilder: (context, index) {
                                      final card = cards[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: CreditCardView(
                                          card: card,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              zoomFromCenterRoute(
                                                CardDetailsScreen(card: card),
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
                                  onReorderItem: (oldIndex, newIndex) {
                                    ref
                                        .read(cardNotifierProvider.notifier)
                                        .reorderCards(oldIndex, newIndex);
                                  },
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    return SwipeableCardTile(
                                      key: ValueKey(card.id),
                                      card: card,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          zoomFromCenterRoute(
                                            CardDetailsScreen(card: card),
                                          ),
                                        );
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
      ),

      // Custom Floating Bottom Navigation Bar (Mathematically Centered 3-Column Grid)
      bottomNavigationBar: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              final activeColor =
                  isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy;
              final inactiveColor =
                  isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

              return Row(
                children: [
                  // Left Tab: Home (33.3% width slot)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _selectedTab == 0
                                  ? Icons.home_rounded
                                  : Icons.home_outlined,
                              color: _selectedTab == 0 ? activeColor : inactiveColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 0 ? activeColor : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Tab: Add Card Button (Rounded Square Navy Tile with Text)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          slideUpRoute(const AddEditCardScreen()),
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_card_rounded,
                              color: isDark ? Colors.black : Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add Card',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Tab: Settings (33.3% width slot)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _selectedTab == 1
                                  ? Icons.settings_rounded
                                  : Icons.settings_outlined,
                              color: _selectedTab == 1 ? activeColor : inactiveColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 1 ? activeColor : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Cards Tracked Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your credit cards to track the 365-day deactivation countdown!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  slideUpRoute(const AddEditCardScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.primaryAccentDark
                    : AppTheme.primaryNavy,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Add First Card',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
