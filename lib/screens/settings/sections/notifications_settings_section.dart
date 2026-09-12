import 'package:flutter/material.dart';
import '../../../models/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tiles.dart';

/// Section for configuring transaction reminder schedules and notification preferences.
class NotificationsSettingsSection extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;

  const NotificationsSettingsSection({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          title: 'NOTIFICATION REMINDERS',
          icon: Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
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
              // Master Notification Switch Row
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onUpdateSettings(
                  settings.copyWith(
                    notificationsEnabled: !settings.notificationsEnabled,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: settings.notificationsEnabled
                              ? (isDark
                                  ? AppTheme.primaryAccentDark
                                      .withValues(alpha: 0.15)
                                  : AppTheme.primaryNavy
                                      .withValues(alpha: 0.08))
                              : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          settings.notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          size: 20,
                          color: settings.notificationsEnabled
                              ? (isDark
                                  ? AppTheme.primaryAccentDark
                                  : AppTheme.primaryNavy)
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Reminders',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.notificationsEnabled
                                  ? 'Receive alerts before 365-day expiry'
                                  : 'Reminders are paused',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        trackOutlineColor:
                            const WidgetStatePropertyAll(Colors.transparent),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return isDark
                                ? AppTheme.primaryAccentDark
                                : AppTheme.primaryNavy;
                          }
                          return isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1);
                        }),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white;
                          }
                          return isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.white;
                        }),
                        value: settings.notificationsEnabled,
                        onChanged: (val) => onUpdateSettings(
                          settings.copyWith(notificationsEnabled: val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: settings.notificationsEnabled
                    ? Column(
                        children: [
                          Divider(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.1),
                          ),
                          ReminderToggleRow(
                            title: '30 Days Before Expiry',
                            value: settings.notify30Days,
                            onChanged: (val) => onUpdateSettings(
                              settings.copyWith(notify30Days: val),
                            ),
                          ),
                          ReminderToggleRow(
                            title: '14 Days Before Expiry',
                            value: settings.notify14Days,
                            onChanged: (val) => onUpdateSettings(
                              settings.copyWith(notify14Days: val),
                            ),
                          ),
                          ReminderToggleRow(
                            title: '7 Days Before Expiry',
                            value: settings.notify7Days,
                            onChanged: (val) => onUpdateSettings(
                              settings.copyWith(notify7Days: val),
                            ),
                          ),
                          ReminderToggleRow(
                            title: '1 Day Before Expiry',
                            value: settings.notify1Day,
                            onChanged: (val) => onUpdateSettings(
                              settings.copyWith(notify1Day: val),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
