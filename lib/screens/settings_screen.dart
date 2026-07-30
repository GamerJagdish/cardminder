import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openGitHub(BuildContext context) async {
    const urlStr = 'https://github.com/GamerJagdish/cardminder';
    final Uri url = Uri.parse(urlStr);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await Clipboard.setData(const ClipboardData(text: urlStr));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GitHub link copied to clipboard!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: urlStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub link copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final cards = ref.watch(cardNotifierProvider).cards;

    void update(AppSettings newSettings) {
      ref
          .read(settingsNotifierProvider.notifier)
          .updateSettings(newSettings, cards);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: HOME SCREEN WIDGET CONTROLS
            const _SectionHeader(
              title: 'HOME SCREEN WIDGET',
              icon: Icons.widgets_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Max Cards Limit Segmented Selector
                  const Text(
                    'Max Cards Shown on Widget',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [3, 5, 10, 100].map((count) {
                      final label = count == 100 ? 'All' : '$count';
                      final isSelected = settings.widgetMaxCards == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () =>
                                update(settings.copyWith(widgetMaxCards: count)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryNavy
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // 2. Urgency Filter Pill Shape Selector
                  const Text(
                    'Widget Cards Filter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PillOption(
                        label: 'All Cards',
                        isSelected: settings.widgetFilter == 'all',
                        onTap: () =>
                            update(settings.copyWith(widgetFilter: 'all')),
                      ),
                      _PillOption(
                        label: '< 90 Days',
                        isSelected:
                            settings.widgetFilter == 'warning_and_urgent',
                        onTap: () => update(settings.copyWith(
                            widgetFilter: 'warning_and_urgent')),
                      ),
                      _PillOption(
                        label: '< 30 Days',
                        isSelected: settings.widgetFilter == 'action_needed',
                        onTap: () => update(
                            settings.copyWith(widgetFilter: 'action_needed')),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // 3. Widget Sort Order Pill Shape Selector
                  const Text(
                    'Widget Sort Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PillOption(
                        label: 'By Urgency',
                        isSelected: settings.widgetSortBy == 'urgency',
                        onTap: () =>
                            update(settings.copyWith(widgetSortBy: 'urgency')),
                      ),
                      _PillOption(
                        label: 'By Name',
                        isSelected: settings.widgetSortBy == 'name',
                        onTap: () =>
                            update(settings.copyWith(widgetSortBy: 'name')),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION 2: NOTIFICATION PREFERENCES
            const _SectionHeader(
              title: 'NOTIFICATION REMINDERS',
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  // Master Notification Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppTheme.primaryNavy,
                    title: const Text(
                      'Transaction Reminders',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Receive alerts before 365-day expiry',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    value: settings.notificationsEnabled,
                    onChanged: (val) =>
                        update(settings.copyWith(notificationsEnabled: val)),
                  ),

                  if (settings.notificationsEnabled) ...[
                    const Divider(color: Color(0xFFF1F5F9)),
                    _ReminderToggleRow(
                      title: '30 Days Before Expiry',
                      value: settings.notify30Days,
                      onChanged: (val) =>
                          update(settings.copyWith(notify30Days: val)),
                    ),
                    _ReminderToggleRow(
                      title: '14 Days Before Expiry',
                      value: settings.notify14Days,
                      onChanged: (val) =>
                          update(settings.copyWith(notify14Days: val)),
                    ),
                    _ReminderToggleRow(
                      title: '7 Days Before Expiry',
                      value: settings.notify7Days,
                      onChanged: (val) =>
                          update(settings.copyWith(notify7Days: val)),
                    ),
                    _ReminderToggleRow(
                      title: '1 Day Before Expiry',
                      value: settings.notify1Day,
                      onChanged: (val) =>
                          update(settings.copyWith(notify1Day: val)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION 3: DEVELOPER & ABOUT
            const _SectionHeader(
              title: 'DEVELOPER & ABOUT',
              icon: Icons.code_rounded,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.primaryNavy,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Developer',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'GamerJagdish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Clickable GitHub Tile
                  InkWell(
                    onTap: () => _openGitHub(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: AppTheme.primaryNavy,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'GitHub Repository',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'github.com/GamerJagdish/cardminder',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION: DATA & BACKUP
            const _SectionHeader(
              title: 'DATA & BACKUP',
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  // Create Backup
                  InkWell(
                    onTap: () async {
                      final success = await BackupService.createAndShareBackup(
                        cards: cards,
                        settings: settings,
                      );
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Encrypted backup exported (.cmbk)'),
                            backgroundColor: AppTheme.accentEmerald,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: AppTheme.primaryNavy,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Backup (.cmbk)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'AES-256 encrypted export of cards & settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFF1F5F9)),
                  ),

                  // Restore Backup
                  InkWell(
                    onTap: () async {
                      try {
                        final backupData = await BackupService.pickAndDecryptBackup();
                        if (backupData == null) return;

                        if (context.mounted) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentEmerald
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.restore_page_rounded,
                                            color: AppTheme.accentEmerald,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Restore Backup?',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Found ${backupData.cards.length} card(s) from backup created on ${DateFormat('MMM dd, yyyy • hh:mm a').format(backupData.exportDate)}.\n\nRestoring will overwrite your current card list.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textDark,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              side: const BorderSide(
                                                  color: Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppTheme.textDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryNavy,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, true),
                                            child: const Text(
                                              'Restore',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (confirm == true) {
                            final storage = ref.read(storageServiceProvider);
                            await storage.saveAllCards(backupData.cards);

                            ref
                                .read(cardNotifierProvider.notifier)
                                .reloadCards();
                            ref.read(settingsNotifierProvider.notifier).updateSettings(
                                  backupData.settings,
                                  backupData.cards,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Restored ${backupData.cards.length} card(s) successfully!'),
                                  backgroundColor: AppTheme.accentEmerald,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to restore backup: ${e.toString().replaceAll("FormatException: ", "")}'),
                              backgroundColor: AppTheme.accentRose,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentEmerald
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.download_for_offline_rounded,
                              color: AppTheme.accentEmerald,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restore Backup (.cmbk)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Decrypt and import your saved .cmbk file',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            if (kDebugMode) ...[
              const _SectionHeader(
                title: 'DEBUG: NOTIFICATION TOOLS',
                icon: Icons.bug_report_outlined,
              ),
              const SizedBox(height: 12),
              const _DebugNotificationTools(),
              const SizedBox(height: 28),
            ],

            // Force Refresh / Sync Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateSettings(settings, cards);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Widget & Reminders synced successfully!'),
                      backgroundColor: AppTheme.accentEmerald,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.sync_rounded, size: 20),
                label: const Text(
                  'Sync Widget & Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppTheme.primaryNavy : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryNavy),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ReminderToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          Checkbox(
            value: value,
            activeColor: AppTheme.primaryNavy,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

class _DebugNotificationTools extends StatefulWidget {
  const _DebugNotificationTools();

  @override
  State<_DebugNotificationTools> createState() =>
      _DebugNotificationToolsState();
}

class _DebugNotificationToolsState extends State<_DebugNotificationTools> {
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
        color: Colors.white,
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
          _DebugActionButton(
            icon: Icons.notifications_active_outlined,
            label: 'Send test notification now',
            busy: _busy,
            onPressed: () => _run(
              NotificationService.showTestNotification,
              'Test notification sent.',
            ),
          ),
          const SizedBox(height: 8),
          _DebugActionButton(
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
          _DebugActionButton(
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

class _DebugActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const _DebugActionButton({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryNavy,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
