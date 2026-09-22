import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/notification_log_service.dart';
import '../theme/app_theme.dart';

class NotificationLogsScreen extends ConsumerStatefulWidget {
  const NotificationLogsScreen({super.key});

  @override
  ConsumerState<NotificationLogsScreen> createState() =>
      _NotificationLogsScreenState();
}

class _NotificationLogsScreenState
    extends ConsumerState<NotificationLogsScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically mark all as read when opening notification history
    Future.microtask(() {
      ref.read(notificationLogNotifierProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(notificationLogNotifierProvider);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
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
        actions: [
          if (logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: () {
                  ref
                      .read(notificationLogNotifierProvider.notifier)
                      .clearLogs();
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppTheme.accentRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: logs.isEmpty
          ? _buildEmptyLogs(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isUrgent = log.daysRemaining <= 30;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.cardShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? (isDark
                                  ? AppTheme.accentRose.withValues(alpha: 0.2)
                                  : AppTheme.badgeUrgentBgLight)
                              : (isDark
                                  ? AppTheme.accentAmber.withValues(alpha: 0.2)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log.cardName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isUrgent
                                        ? (isDark
                                            ? AppTheme.accentRose
                                                .withValues(alpha: 0.2)
                                            : AppTheme.badgeUrgentBgLight)
                                        : (isDark
                                            ? AppTheme.accentEmerald
                                                .withValues(alpha: 0.2)
                                            : AppTheme.badgeSafeBgLight),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${log.daysRemaining}d left',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isUrgent
                                          ? AppTheme.accentRose
                                          : AppTheme.accentEmerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFormat.format(log.timestamp),
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
                );
              },
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
