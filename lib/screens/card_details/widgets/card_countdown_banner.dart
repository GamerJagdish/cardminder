import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/credit_card.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/animated_odometer.dart';

class CardCountdownBanner extends StatelessWidget {
  final CreditCard card;
  final bool showCelebration;
  final VoidCallback onEditLastTransactionDate;

  const CardCountdownBanner({
    super.key,
    required this.card,
    required this.showCelebration,
    required this.onEditLastTransactionDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgency = card.status;
    final progress = card.elapsedProgress;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final pillBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9);
    final dividerColor = isDark
        ? const Color(0xFF2A3446)
        : const Color(0xFFE2E8F0);
    final labelColor = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: showCelebration
            ? AppTheme.accentEmerald.withValues(alpha: isDark ? 0.20 : 0.10)
            : pillBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: showCelebration
              ? AppTheme.accentEmerald.withValues(alpha: isDark ? 0.5 : 0.35)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: showCelebration
            ? [
                BoxShadow(
                  color: AppTheme.accentEmerald
                      .withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Circular Progress Ring with integrated Status Pill, Number, and Label
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 134,
                  height: 134,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0.0, end: (1.0 - progress).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      return CircularProgressIndicator(
                        value: animatedValue,
                        strokeWidth: 8.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? const Color(0xFF283244)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? (urgency == UrgencyStatus.safe
                                  ? AppTheme.badgeSafeFgDark
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
                    // Status Pill on top of number inside the circle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: urgency.badgeBgColor(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            urgency.label,
                            style: TextStyle(
                              color: urgency.badgeTextColor(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (showCelebration) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.accentEmerald,
                              size: 11,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedOdometerText(
                      value: card.daysRemaining,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DAYS LEFT',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Subtitle
          Center(
            child: Text(
              showCelebration
                  ? 'Card refreshed & active!'
                  : (card.daysRemaining <= 0
                      ? 'Card deactivated'
                      : 'to avoid deactivation'),
              style: TextStyle(
                fontSize: 13,
                color: showCelebration
                    ? AppTheme.accentEmerald
                    : labelColor,
                fontWeight: showCelebration
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Divider between Countdown & Timeline Details
          Container(
            height: 1,
            color: dividerColor,
          ),

          const SizedBox(height: 14),

          // Bottom Section: Last Transaction & Deactivation Deadline
          Row(
            children: [
              // Last Transaction (Tappable to Edit)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditLastTransactionDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Last transaction',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: labelColor,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_calendar_outlined,
                                size: 13,
                                color: labelColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(card.lastTransactionDate),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle vertical separator between dates
              Container(
                width: 1,
                height: 36,
                color: dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Deactivation Deadline
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deactivation deadline',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(card.deactivationDate),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
