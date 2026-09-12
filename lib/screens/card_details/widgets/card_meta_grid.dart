import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/credit_card.dart';
import '../../../theme/app_theme.dart';

class CardMetaGrid extends StatelessWidget {
  final CreditCard card;
  final VoidCallback onEditLastTransactionDate;

  const CardMetaGrid({
    super.key,
    required this.card,
    required this.onEditLastTransactionDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('meta-${card.id}'),
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
                  child: CardMetaItem(
                    label: 'LAST TRANSACTION',
                    value: dateFormat.format(card.lastTransactionDate),
                    onTap: onEditLastTransactionDate,
                  ),
                ),
                Expanded(
                  child: CardMetaItem(
                    label: 'DEADLINE',
                    value: dateFormat.format(card.deactivationDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CardMetaItem(
                    label: 'NETWORK',
                    value: card.network,
                  ),
                ),
                Expanded(
                  child: CardMetaItem(
                    label: 'EXPIRES',
                    value: card.expiryDateString,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CardMetaItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const CardMetaItem({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_outlined,
                size: 11,
                color: AppTheme.textMuted,
              ),
            ],
          ],
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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
