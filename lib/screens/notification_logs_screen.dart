import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/notification_log.dart';
import '../providers/card_provider.dart';
import '../services/notification_log_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/snackbar_utils.dart';
import 'card_details_screen.dart';

/// Formats notification timestamps into natural human language:
/// - Today: "Today at 3:30 PM (2h ago)"
/// - Yesterday: "Yesterday at 3:30 PM"
/// - Earlier: "Sep 25 at 3:30 PM" (or with year if older)
String formatNotificationTimestamp(DateTime timestamp, [DateTime? nowOverride]) {
  final now = nowOverride ?? DateTime.now();
  final timeStr = DateFormat('h:mm a').format(timestamp);

  final today = DateTime(now.year, now.month, now.day);
  final itemDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final diffDays = today.difference(itemDate).inDays;

  if (diffDays <= 0) {
    final diff = now.difference(timestamp);
    final String relative;
    if (diff.isNegative || diff.inSeconds < 60) {
      relative = 'just now';
    } else if (diff.inMinutes < 60) {
      relative = '${diff.inMinutes}m ago';
    } else {
      relative = '${diff.inHours}h ago';
    }
    return 'Today at $timeStr ($relative)';
  } else if (diffDays == 1) {
    return 'Yesterday at $timeStr';
  } else if (timestamp.year == now.year) {
    final dateStr = DateFormat('MMM d').format(timestamp);
    return '$dateStr at $timeStr';
  } else {
    final dateStr = DateFormat('MMM d, yyyy').format(timestamp);
    return '$dateStr at $timeStr';
  }
}

class NotificationLogsScreen extends ConsumerStatefulWidget {
  const NotificationLogsScreen({super.key});

  @override
  ConsumerState<NotificationLogsScreen> createState() =>
      _NotificationLogsScreenState();
}

class _NotificationLogsScreenState
    extends ConsumerState<NotificationLogsScreen> {
  void _handleLogTap(BuildContext context, NotificationLog log) {
    final cards = ref.read(cardNotifierProvider).cards;
    final card = cards.where((c) => c.id == log.cardId).firstOrNull;
    if (card != null) {
      if (!log.isRead) {
        ref
            .read(notificationLogNotifierProvider.notifier)
            .setReadStatus(log.id, true);
      }
      Navigator.push(
        context,
        slideUpRoute(CardDetailsScreen(card: card)),
      );
    } else {
      showAppErrorSnackBar(
        context,
        title: 'Card Not Found',
        message: 'This card was deleted or no longer exists.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(notificationLogNotifierProvider);
    final unreadCount = logs.where((l) => !l.isRead).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 14.0),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.circleButtonBg,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Notifications History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            shadows: AppTheme.textShadowAmbient(isDark),
          ),
        ),
      ),
      body: logs.isEmpty
          ? _buildEmptyLogs(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF161B26).withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < logs.length; i++)
                                _SwipeableNotificationTile(
                                  key: ValueKey(logs[i].id),
                                  log: logs[i],
                                  showDivider: i < logs.length - 1,
                                  onTap: () => _handleLogTap(context, logs[i]),
                                  onSwipeRead: () {
                                    ref
                                        .read(
                                            notificationLogNotifierProvider.notifier)
                                        .setReadStatus(logs[i].id, true);
                                  },
                                  onSwipeUnread: () {
                                    ref
                                        .read(
                                            notificationLogNotifierProvider.notifier)
                                        .setReadStatus(logs[i].id, false);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: unreadCount > 0
                            ? () {
                                ref
                                    .read(
                                        notificationLogNotifierProvider.notifier)
                                    .markAllAsRead();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.buttonPrimaryBg,
                          foregroundColor: context.colors.buttonPrimaryFg,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          disabledForegroundColor: AppTheme.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: unreadCount > 0 ? 2 : 0,
                        ),
                        child: Text(
                          unreadCount > 0
                              ? 'Mark all as read'
                              : 'All notifications read',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: unreadCount > 0
                                ? context.colors.buttonPrimaryFg
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyLogs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 56,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'CardMinder will log all notifications here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableNotificationTile extends StatelessWidget {
  final NotificationLog log;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onSwipeRead;
  final VoidCallback onSwipeUnread;

  const _SwipeableNotificationTile({
    super.key,
    required this.log,
    this.showDivider = false,
    required this.onTap,
    required this.onSwipeRead,
    required this.onSwipeUnread,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUrgent = log.daysRemaining <= 30;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dismissible(
          key: Key('dismiss_${log.id}'),
          background: _SwipeActionBackground(
            color: context.colors.editActionBg,
            alignment: Alignment.centerLeft,
            icon: Icons.mark_email_unread_rounded,
            label: 'Mark as unread',
          ),
          secondaryBackground: const _SwipeActionBackground(
            color: AppTheme.accentEmerald,
            alignment: Alignment.centerRight,
            icon: Icons.done_all_rounded,
            label: 'Mark as read',
            iconAfterLabel: true,
          ),
          onUpdate: (details) {
            if (details.reached && !details.previousReached) {
              HapticFeedback.mediumImpact();
            }
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              onSwipeUnread();
            } else if (direction == DismissDirection.endToStart) {
              onSwipeRead();
            }
            return false;
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Opacity(
                opacity: log.isRead ? 0.60 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? (isDark
                                  ? AppTheme.accentRose
                                      .withValues(alpha: 0.18)
                                  : AppTheme.badgeUrgentBgLight)
                              : (isDark
                                  ? AppTheme.accentAmber
                                      .withValues(alpha: 0.18)
                                  : AppTheme.badgeWarningBgLight),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: isUrgent
                              ? AppTheme.accentRose
                              : AppTheme.accentAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.cardName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: log.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${log.daysRemaining} day${log.daysRemaining == 1 ? '' : 's'} left until deactivation',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: log.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                color: log.isRead
                                    ? AppTheme.textMuted
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatNotificationTimestamp(log.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
      ],
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
        color: AppTheme.surfaceWhite,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    final iconWidget = Icon(icon, color: AppTheme.surfaceWhite, size: 22);

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
