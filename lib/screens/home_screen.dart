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
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
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
                      color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.primaryNavy,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Your Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryNavy, width: 1.5),
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
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
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
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
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

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
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
                        GestureDetector(
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                  color: const Color(0xFFFEE2E2)
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
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
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: isSelected ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryNavy
                                            : const Color(0xFFCBD5E1),
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
                                      const Text(
                                        'All Cards',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
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
                                            color: AppTheme.primaryNavy
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.primaryNavy
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
                                                color: AppTheme.primaryNavy,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                state.sortMode ==
                                                        SortMode.urgency
                                                    ? 'Sorted by urgency'
                                                    : 'User Defined',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.primaryNavy,
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
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
                              ? AppTheme.primaryNavy.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedTab == 0
                              ? Icons.home_rounded
                              : Icons.home_outlined,
                          color: _selectedTab == 0
                              ? AppTheme.primaryNavy
                              : AppTheme.textMuted,
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
                          color: _selectedTab == 0
                              ? AppTheme.primaryNavy
                              : AppTheme.textMuted,
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
                          color: AppTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryNavy.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Add Card',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
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
                              ? AppTheme.primaryNavy.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedTab == 1
                              ? Icons.settings_rounded
                              : Icons.settings_outlined,
                          color: _selectedTab == 1
                              ? AppTheme.primaryNavy
                              : AppTheme.textMuted,
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
                          color: _selectedTab == 1
                              ? AppTheme.primaryNavy
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_off_outlined,
                size: 56,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Cards Tracked Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  slideUpRoute(const AddEditCardScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add First Card',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
