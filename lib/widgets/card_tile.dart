import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../theme/app_theme.dart';

class SwipeableCardTile extends StatelessWidget {
  final CreditCard card;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<bool> Function() onDeleteConfirm;

  const SwipeableCardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onEdit,
    required this.onDeleteConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Dismissible(
            key: Key(card.id),
            background: _SwipeActionBackground(
              color: AppTheme.primaryNavy,
              alignment: Alignment.centerLeft,
              icon: Icons.edit,
              label: 'Edit',
            ),
            secondaryBackground: _SwipeActionBackground(
              color: AppTheme.accentRose,
              alignment: Alignment.centerRight,
              icon: Icons.delete_outline,
              label: 'Delete',
              iconAfterLabel: true,
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                onEdit();
                return false;
              }
              if (direction == DismissDirection.endToStart) {
                return onDeleteConfirm();
              }
              return false;
            },
            child: Material(
              color: Theme.of(context).cardTheme.color,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CardTileBody(card: card),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final IconData icon;
  final String label;
  final bool iconAfterLabel;

  const _SwipeActionBackground({
    required this.color,
    required this.alignment,
    required this.icon,
    required this.label,
    this.iconAfterLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    final iconWidget = Icon(icon, color: Colors.white, size: 22);

    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconAfterLabel
            ? [labelWidget, const SizedBox(width: 8), iconWidget]
            : [iconWidget, const SizedBox(width: 8), labelWidget],
      ),
    );
  }
}

class _CardTileBody extends StatelessWidget {
  final CreditCard card;

  const _CardTileBody({required this.card});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final urgency = card.status;
    final digits = card.lastFourDigits ?? '0000';
    final cardColors = AppTheme.getCardColors(card.colorIndex);

    // Compute contrast text color for thumbnail badge if needed
    final isThumbnailLight = cardColors.first.computeLuminance() > 0.45;
    final thumbnailTextColor = isThumbnailLight ? const Color(0xFF0F172A) : Colors.white;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 54,
          height: 44,
          decoration: BoxDecoration(
            color: cardColors.first,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            digits,
            style: TextStyle(
              color: thumbnailTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.cardName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${card.network} • Last: ${dateFormat.format(card.lastTransactionDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${card.daysRemaining}d',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: urgency.badgeTextColor(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: urgency.badgeBgColor(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                urgency.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: urgency.badgeTextColor(isDark),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
