import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import 'settings_tiles.dart';

/// Developer diagnostics and live test notification trigger container.
class DebugNotificationTools extends StatefulWidget {
  const DebugNotificationTools({super.key});

  @override
  State<DebugNotificationTools> createState() => _DebugNotificationToolsState();
}

class _DebugNotificationToolsState extends State<DebugNotificationTools> {
  bool _busy = false;
  String? _status;

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _status = successMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showPendingNotifications() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final pending = await NotificationService.getPendingNotifications();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Pending notifications (${pending.length})'),
          content: pending.isEmpty
              ? const Text('No notifications are scheduled with the OS.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final item = pending[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID ${item.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          if (item.title != null) ...[
                            const SizedBox(height: 4),
                            Text(item.title!),
                          ],
                          if (item.body != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.body!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (mounted) {
        setState(() => _status = '${pending.length} pending notification(s)');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          DebugActionButton(
            icon: Icons.notifications_active_outlined,
            label: 'Send test notification now',
            busy: _busy,
            onPressed: () => _run(
              NotificationService.showTestNotification,
              'Test notification sent.',
            ),
          ),
          const SizedBox(height: 8),
          DebugActionButton(
            icon: Icons.schedule_outlined,
            label: 'Schedule test in 1 minute',
            busy: _busy,
            onPressed: () async {
              setState(() {
                _busy = true;
                _status = null;
              });
              try {
                final when =
                    await NotificationService.scheduleTestNotificationInOneMinute();
                if (mounted) {
                  setState(() => _status =
                      'Scheduled for ${DateFormat.jm().format(when)}');
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _status = 'Failed: $e');
                }
              } finally {
                if (mounted) {
                  setState(() => _busy = false);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          DebugActionButton(
            icon: Icons.list_alt_outlined,
            label: 'View pending scheduled notifications',
            busy: _busy,
            onPressed: _showPendingNotifications,
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: TextStyle(
                fontSize: 12,
                color: _status!.startsWith('Failed')
                    ? AppTheme.accentRose
                    : AppTheme.accentEmerald,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
