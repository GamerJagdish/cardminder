import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_log_service.dart';
import '../theme/app_theme.dart';
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Your Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final settings = ref.read(settingsNotifierProvider);
                ref
                    .read(settingsNotifierProvider.notifier)
                    .updateSettings(settings.copyWith(userName: newName), cards.cast());
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardNotifierProvider);
    final cards = state.cards;
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
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CardDetailsScreen(
                                                        card: card),
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
                                    children: const [
                                      Text(
                                        'All Cards',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Sorted by urgency',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Cards List
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cards.length,
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    return Dismissible(
                                      key: Key(card.id),
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20.0, vertical: 6.0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryNavy,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: const [
                                            Icon(Icons.edit,
                                                color: Colors.white, size: 22),
                                            SizedBox(width: 8),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20.0, vertical: 6.0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentRose,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.delete_outline,
                                                color: Colors.white, size: 22),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddEditCardScreen(cardToEdit: card),
                                            ),
                                          );
                                          return false;
                                        } else if (direction ==
                                            DismissDirection.endToStart) {
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
                                        }
                                        return false;
                                      },
                                      child: CardTile(
                                        card: card,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CardDetailsScreen(card: card),
                                            ),
                                          );
                                        },
                                      ),
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

      // Custom Floating Bottom Navigation Bar
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab
            GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    color: _selectedTab == 0
                        ? AppTheme.primaryNavy
                        : AppTheme.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _selectedTab == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTab == 0
                          ? AppTheme.primaryNavy
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Floating Circular Add Button (+)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditCardScreen(),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryNavy,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),

            // Settings Tab
            GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings_outlined,
                    color: _selectedTab == 1
                        ? AppTheme.primaryNavy
                        : AppTheme.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _selectedTab == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTab == 1
                          ? AppTheme.primaryNavy
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  MaterialPageRoute(
                    builder: (_) => const AddEditCardScreen(),
                  ),
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
