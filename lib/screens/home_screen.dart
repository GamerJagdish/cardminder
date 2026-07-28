import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/add_edit_card_sheet.dart';
import '../widgets/stats_header.dart';
import 'card_details_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const AddEditCardSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardNotifierProvider);
    final filteredCards = state.filteredCards;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.credit_card_sharp,
                color: AppTheme.primaryViolet,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CardMinder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '365-Day Inactivity Guardian',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (query) {
                ref.read(cardNotifierProvider.notifier).setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search card name or digits...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(cardNotifierProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Quick Filter Stats Header
          const StatsHeader(),

          const SizedBox(height: 8),

          // Credit Cards List / Empty State
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryViolet),
                  )
                : filteredCards.isEmpty
                    ? _buildEmptyState(state.cards.isEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = filteredCards[index];
                          return CreditCardView(
                            card: card,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: AppTheme.surfaceDark,
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.vertical(top: Radius.circular(28)),
                                ),
                                builder: (_) => CardDetailsSheet(card: card),
                              );
                            },
                            onEdit: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: AppTheme.surfaceDark,
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.vertical(top: Radius.circular(28)),
                                ),
                                builder: (_) => AddEditCardSheet(cardToEdit: card),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),

      // Add Card Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCardSheet,
        backgroundColor: AppTheme.primaryViolet,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text(
          'Add Card',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isNoCardsAdded) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryViolet.withValues(alpha: 0.12),
              ),
              child: Icon(
                isNoCardsAdded
                    ? Icons.credit_card_off_rounded
                    : Icons.search_off_rounded,
                size: 56,
                color: AppTheme.primaryViolet,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNoCardsAdded ? 'No Credit Cards Tracked' : 'No Cards Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNoCardsAdded
                  ? 'Add your credit cards to start tracking the 365-day deactivation countdown and receive reminders!'
                  : 'Try searching with a different name or clear filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            if (isNoCardsAdded) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openAddCardSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
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
          ],
        ),
      ),
    );
  }
}
