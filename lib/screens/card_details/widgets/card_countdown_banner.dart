import 'package:flutter/material.dart';
import '../../../models/credit_card.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/animated_odometer.dart';

class CardCountdownBanner extends StatelessWidget {
  final CreditCard card;
  final bool showCelebration;

  const CardCountdownBanner({
    super.key,
    required this.card,
    required this.showCelebration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgency = card.status;
    final progress = card.elapsedProgress;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: showCelebration
            ? AppTheme.accentEmerald
                .withValues(alpha: isDark ? 0.20 : 0.10)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: showCelebration
              ? AppTheme.accentEmerald
                  .withValues(alpha: isDark ? 0.5 : 0.35)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: showCelebration
                ? AppTheme.accentEmerald
                    .withValues(alpha: isDark ? 0.25 : 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: showCelebration ? 18 : 10,
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                      begin: 0.0, end: (1.0 - progress).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return CircularProgressIndicator(
                      value: animatedValue,
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
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOdometerText(
                    value: card.daysRemaining,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgency.badgeBgColor(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        urgency.label,
                        style: TextStyle(
                          color: urgency.badgeTextColor(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (showCelebration) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.accentEmerald,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AnimatedOdometerText(
                      value: card.daysRemaining,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'days left',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  showCelebration
                      ? 'Card refreshed & active!'
                      : 'to avoid deactivation',
                  style: TextStyle(
                    fontSize: 13,
                    color: showCelebration
                        ? AppTheme.accentEmerald
                        : AppTheme.textMuted,
                    fontWeight: showCelebration
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
