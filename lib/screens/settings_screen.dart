import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
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
