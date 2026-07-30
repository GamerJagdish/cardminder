import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/credit_card_view.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'add_edit_card_screen.dart';

class CardDetailsScreen extends ConsumerWidget {
  final CreditCard card;

  const CardDetailsScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically watch card state to reflect instant edits
    final cards = ref.watch(cardNotifierProvider).cards;
    final currentCard = cards.firstWhere(
      (c) => c.id == card.id,
      orElse: () => card,
    );

    final dateFormat = DateFormat('MMM dd, yyyy');
    final urgency = currentCard.status;
    final progress = currentCard.elapsedProgress;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),
        title: Text(currentCard.cardName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Featured Card Graphic (Tap to Edit)
            CreditCardView(
              card: currentCard,
              onTap: () {
                Navigator.push(
                  context,
                  slideUpRoute(AddEditCardScreen(cardToEdit: currentCard)),
                );
              },
            ),

            const SizedBox(height: 20),

            // Countdown Progress Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular Progress Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 1.0 - progress,
                          strokeWidth: 8,
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? (urgency == UrgencyStatus.safe
                                    ? const Color(0xFF34D399)
                                    : urgency.badgeTextColor(isDark))
                                : urgency.color,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${currentCard.daysRemaining}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Text(
                            'DAYS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgency.badgeBgColor(isDark),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: urgency.badgeTextColor(isDark),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                urgency.label,
                                style: TextStyle(
                                  color: urgency.badgeTextColor(isDark),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentCard.daysRemaining} days left',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'to avoid deactivation',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metadata 2x2 Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetaItem(
                          label: 'LAST TRANSACTION',
                          value: dateFormat.format(currentCard.lastTransactionDate),
                        ),
                      ),
                      Expanded(
                        child: _MetaItem(
                          label: 'DEADLINE',
                          value: dateFormat.format(currentCard.deactivationDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetaItem(
                          label: 'NETWORK',
                          value: currentCard.network,
                        ),
                      ),
                      Expanded(
                        child: _MetaItem(
                          label: 'EXPIRES',
                          value: currentCard.expiryDateString,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Primary Action Button: "Mark Transaction Today"
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(cardNotifierProvider.notifier)
                      .markUsedToday(currentCard.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${currentCard.cardName} reset for 365 days!'),
                      backgroundColor: AppTheme.accentEmerald,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppTheme.primaryAccentDark
                      : AppTheme.primaryNavy,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Mark Transaction Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary Actions Row: Edit & Delete Buttons (No Icons)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          slideUpRoute(
                            AddEditCardScreen(cardToEdit: currentCard),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardTheme.color,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => _confirmDelete(context, ref, currentCard),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardTheme.color,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.accentRose.withValues(alpha: 0.4)
                              : const Color(0xFFFECDD3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRose,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CreditCard targetCard) async {
    final confirm = await showDeleteConfirmationDialog(
      context: context,
      cardName: targetCard.cardName,
    );

    if (confirm == true) {
      ref.read(cardNotifierProvider.notifier).deleteCard(targetCard.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
