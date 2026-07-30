import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import '../models/credit_card.dart';
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

  Future<void> _showCreateBackupPinDialog(
    BuildContext context,
    List<CreditCard> cards,
    AppSettings settings,
  ) async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final pin = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set Pin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'enter a 4 digit pin to lock your backup file it will be needed when you restore it.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pinController,
                  autofocus: true,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(dialogCtx, pinController.text.trim());
                    }
                  },
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0000',
                    counterText: '',
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.length != 4) {
                      return 'Please enter a 4-digit PIN';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, null),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.primaryAccentDark
                              : AppTheme.primaryNavy,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(dialogCtx, pinController.text.trim());
                          }
                        },
                        child: Text(
                          'Backup',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
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
      ),
    );

    if (pin == null || pin.isEmpty) return;

    final err = await BackupService.createAndShareBackup(
      cards: cards,
      settings: settings,
      userPin: pin,
    );

    if (context.mounted) {
      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: AppTheme.accentEmerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $err'),
            backgroundColor: AppTheme.accentRose,
          ),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup(
      BuildContext context, WidgetRef ref) async {
    final file = await BackupService.pickBackupFile();
    if (file == null) return;

    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userPin = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: AppTheme.accentEmerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enter Pin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'enter the 4 digit pin you used when backing up your file.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pinController,
                  autofocus: true,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(dialogCtx, pinController.text.trim());
                    }
                  },
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0000',
                    counterText: '',
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.length != 4) {
                      return 'Please enter 4-digit PIN';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, null),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.primaryAccentDark
                              : AppTheme.primaryNavy,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(dialogCtx, pinController.text.trim());
                          }
                        },
                        child: Text(
                          'Restore',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
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
      ),
    );

    if (userPin == null || userPin.isEmpty) return;

    try {
      final backupData = await BackupService.decryptBackupFile(
        file: file,
        userPin: userPin,
      );

      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).cardTheme.color,
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
                        color: AppTheme.accentEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restore_page_rounded,
                        color: AppTheme.accentEmerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Restore Backup?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Found ${backupData.cards.length} card(s) from backup created on ${DateFormat('MMM dd, yyyy • hh:mm a').format(backupData.exportDate)}.\n\nRestoring will overwrite your current card list.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.primaryAccentDark
                              : AppTheme.primaryNavy,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(
                          'Restore',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
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

      ref.read(cardNotifierProvider.notifier).reloadCards();
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
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN or corrupted backup file'),
          backgroundColor: AppTheme.accentRose,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final cards = ref.watch(cardNotifierProvider).cards;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    void update(AppSettings newSettings) {
      ref
          .read(settingsNotifierProvider.notifier)
          .updateSettings(newSettings, cards);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 0: APP THEME
            const _SectionHeader(
              title: 'APP THEME',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  _ThemeOptionTile(
                    title: 'System',
                    icon: Icons.phone_android_rounded,
                    isSelected: settings.themeMode == 'system',
                    onTap: () => update(settings.copyWith(themeMode: 'system')),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOptionTile(
                    title: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: settings.themeMode == 'light',
                    onTap: () => update(settings.copyWith(themeMode: 'light')),
                  ),
                  const SizedBox(width: 8),
                  _ThemeOptionTile(
                    title: 'Dark',
                    icon: Icons.nightlight_round,
                    isSelected: settings.themeMode == 'dark',
                    onTap: () => update(settings.copyWith(themeMode: 'dark')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION 1: HOME SCREEN WIDGET CONTROLS
            const _SectionHeader(
              title: 'HOME SCREEN WIDGET',
              icon: Icons.widgets_outlined,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Max Cards Limit Segmented Selector
                  Text(
                    'Max Cards Shown on Widget',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [3, 5, 10, 100].map((count) {
                      final label = count == 100 ? 'All' : '$count';
                      final isSelected = settings.widgetMaxCards == count;
                      return _PillOption(
                        label: label,
                        isSelected: isSelected,
                        onTap: () =>
                            update(settings.copyWith(widgetMaxCards: count)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  // 2. Urgency Filter Pill Shape Selector
                  Text(
                    'Widget Cards Filter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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
                  Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  // 3. Widget Sort Order Pill Shape Selector
                  Text(
                    'Widget Sort Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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
                  // Master Notification Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: isDark
                        ? AppTheme.primaryAccentDark
                        : AppTheme.primaryNavy,
                    thumbColor: WidgetStateProperty.all(
                      isDark ? Colors.black : Colors.white,
                    ),
                    title: Text(
                      'Transaction Reminders',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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

            // SECTION 3: DATA & BACKUP
            const _SectionHeader(
              title: 'DATA & BACKUP',
              icon: Icons.shield_outlined,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup & Restore Options',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Export or restore your card data and settings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Create Backup Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _showCreateBackupPinDialog(context, cards, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Create Backup',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Restore Backup Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleRestoreBackup(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Restore Backup',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // SECTION 4: ABOUT
            const _SectionHeader(
              title: 'ABOUT',
              icon: Icons.info_outline_rounded,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Developer',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GamerJagdish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/logos/github.svg',
                              width: 20,
                              height: 20,
                              colorFilter: isDark
                                  ? const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contribute',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
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
                  backgroundColor: isDark
                      ? AppTheme.primaryAccentDark
                      : AppTheme.primaryNavy,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: isDark ? Colors.black : Colors.white,
                ),
                label: Text(
                  'Sync Widget & Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.black : Colors.white,
                  ),
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

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy;
    final activeFg = isDark ? Colors.black : Colors.white;
    final inactiveBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inactiveFg =
        isDark ? const Color(0xFFF8FAFC) : AppTheme.textDark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeFg : inactiveFg,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? activeFg : inactiveFg,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy;
    final activeFg = isDark ? Colors.black : Colors.white;
    final inactiveBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inactiveFg =
        isDark ? const Color(0xFFF8FAFC) : AppTheme.textDark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeFg : inactiveFg,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Checkbox(
            value: value,
            activeColor: isDark ? AppTheme.primaryAccentDark : AppTheme.primaryNavy,
            checkColor: isDark ? Colors.black : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
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
