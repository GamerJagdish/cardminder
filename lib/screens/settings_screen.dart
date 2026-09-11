import 'package:file_picker/file_picker.dart';
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
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/backup_dialogs.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Future<bool> handleRestoreBackup(
      BuildContext context, WidgetRef ref, AppSettings settings) async {
    final effectiveDir =
        await BackupService.getEffectiveBackupDirectory(settings);
    final file =
        await BackupService.pickBackupFile(initialDirectory: effectiveDir);
    if (file == null) return false;

    if (!context.mounted) return false;

    // 1. Verify file validity BEFORE showing PIN dialog
    final isValid = await BackupService.isValidBackupFile(file);
    if (!context.mounted) return false;
    if (!isValid) {
      showAppErrorSnackBar(
        context,
        title: 'Not a Backup File',
        message: 'The selected file is not a valid CardMinder backup.',
      );
      return false;
    }

    // 2. Show PIN unlock dialog with inline verification & retry
    final backupData = await showDialog<BackupData>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => UnlockBackupPinDialog(file: file),
    );

    if (backupData == null) return false;

    if (!context.mounted) return false;

    // 3. Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => RestoreConfirmDialog(backupData: backupData),
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
        showAppSuccessSnackBar(
          context,
          title: 'Backup Restored Successfully',
          message:
              'Restored ${backupData.cards.length} card(s) and preferences.',
        );
      }
      return true;
    }
    return false;
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _developerClickCount = 0;
  bool _showClownRain = false;
  bool _isCheckingUpdate = false;

  void _handleDeveloperTap() {
    setState(() {
      _developerClickCount++;
    });

    if (_developerClickCount == 3) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("buddy don't click me so hard owo"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_developerClickCount == 6) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("you gotta stop bro it hurts"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_developerClickCount == 9) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("i will show my true colors now stay prepared"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_developerClickCount == 20) {
      setState(() {
        _showClownRain = true;
      });
    }
  }

  Future<void> _openUrl(
    BuildContext context,
    String urlStr,
    String label,
  ) async {
    final Uri url = Uri.parse(urlStr);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await Clipboard.setData(ClipboardData(text: urlStr));
        if (context.mounted) {
          showAppSuccessSnackBar(
            context,
            title: 'Link Copied',
            message: '$label link copied to clipboard!',
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: urlStr));
      if (context.mounted) {
        showAppSuccessSnackBar(
          context,
          title: 'Link Copied',
          message: '$label link copied to clipboard!',
        );
      }
    }
  }

  Future<void> _handleCheckForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      await UpdateService.checkForUpdates(context);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _showCreateBackupPinDialog(
    BuildContext context,
    List<CreditCard> cards,
    AppSettings settings,
  ) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const SetBackupPinDialog(),
    );

    if (pin == null || pin.isEmpty) return;

    final result = await BackupService.createLocalBackup(
      cards: cards,
      settings: settings,
      userPin: pin,
    );

    if (context.mounted) {
      if (result.success && result.file != null) {
        showAppSuccessSnackBar(
          context,
          title: 'Backup Created Successfully',
          message: 'Saved to ${result.fileName}',
          action: SnackBarAction(
            label: 'Share',
            textColor: AppTheme.accentEmerald,
            onPressed: () => BackupService.shareBackupFile(
              file: result.file!,
              fileName: result.fileName!,
            ),
          ),
        );
      } else {
        showAppErrorSnackBar(
          context,
          title: 'Backup Failed',
          message: result.errorMessage ?? 'Could not write backup file.',
        );
      }
    }
  }

  Future<void> _handleChangeBackupLocation(
    BuildContext context,
    AppSettings settings,
    List<CreditCard> cards,
  ) async {
    try {
      final effectiveDir =
          await BackupService.getEffectiveBackupDirectory(settings);
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Backup Folder',
        initialDirectory: effectiveDir,
      );

      if (selectedPath != null && selectedPath.isNotEmpty) {
        final normalizedSelected = BackupService.normalizePath(selectedPath);
        final isDefault =
            await BackupService.isDefaultDirectory(normalizedSelected);

        ref.read(settingsNotifierProvider.notifier).updateSettings(
              settings.copyWith(
                  backupPath: isDefault ? '' : normalizedSelected),
              cards,
            );

        if (context.mounted) {
          if (isDefault) {
            showAppSuccessSnackBar(
              context,
              title: 'Default Folder Selected',
              message: 'Backups will be saved to Documents/CardMinder',
            );
          } else {
            showAppSuccessSnackBar(
              context,
              title: 'Backup Folder Updated',
              message: normalizedSelected,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppErrorSnackBar(
          context,
          title: 'Folder Selection Failed',
          message: e.toString(),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

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
                    children: [100, 3, 5, 10].map((count) {
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
                  // Master Notification Switch Row
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => update(settings.copyWith(
                        notificationsEnabled: !settings.notificationsEnabled)),
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.notificationsEnabled
                                      ? 'Receive alerts before 365-day expiry'
                                      : 'Reminders are paused',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            trackOutlineColor: const WidgetStatePropertyAll(
                                Colors.transparent),
                            trackColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return isDark
                                    ? AppTheme.primaryAccentDark
                                    : AppTheme.primaryNavy;
                              }
                              return isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1);
                            }),
                            thumbColor:
                                WidgetStateProperty.resolveWith((states) {
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
                            onChanged: (val) => update(
                                settings.copyWith(notificationsEnabled: val)),
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
                                      .withValues(alpha: 0.1)),
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
                          )
                        : const SizedBox.shrink(),
                  ),
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
                  // 1. Backup Location Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Backup Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clickable Backup Path Container
                  FutureBuilder<String>(
                    future: BackupService.getEffectiveBackupDirectory(settings),
                    builder: (context, snapshot) {
                      final pathDisplay = snapshot.data ??
                          (settings.backupPath.isNotEmpty
                              ? settings.backupPath
                              : 'Resolving default storage...');
                      final isCustom = settings.backupPath.isNotEmpty;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleChangeBackupLocation(
                              context, settings, cards),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isCustom
                                                  ? AppTheme.accentEmerald
                                                      .withValues(alpha: 0.15)
                                                  : (isDark
                                                      ? const Color(0xFF334155)
                                                      : const Color(0xFFE2E8F0)),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCustom
                                                  ? 'Custom Folder'
                                                  : 'Default Folder',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isCustom
                                                    ? AppTheme.accentEmerald
                                                    : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '•  Tap to change',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        pathDisplay,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontFamily: 'monospace',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCustom)
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 20),
                                    tooltip: 'Reset to default folder',
                                    color: AppTheme.textMuted,
                                    onPressed: () {
                                      update(settings.copyWith(backupPath: ''));
                                      showAppSuccessSnackBar(
                                        context,
                                        title: 'Reset to Default Folder',
                                        message:
                                            'Backups will be saved to Documents/CardMinder',
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.folder_open_rounded,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                  const SizedBox(height: 14),

                  // 2. Backup & Restore Options
                  Text(
                    'Create or Restore Backup',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Backups are encrypted with your private 4-digit PIN.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Create Backup Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showCreateBackupPinDialog(
                              context, cards, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.primaryAccentDark
                                  : AppTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_download_outlined,
                                  size: 16,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Create Backup',
                                  style: TextStyle(
                                    color: isDark ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Restore Backup Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              SettingsScreen.handleRestoreBackup(context, ref, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Restore Backup',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                  // 1. Developer: GamerJagdish (unchanged)
                  InkWell(
                    onTap: _handleDeveloperTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: _developerClickCount >= 12
                                ? const Text(
                                    '🤡',
                                    style: TextStyle(fontSize: 18),
                                  )
                                : Icon(
                                    Icons.person_outline_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                  const SizedBox(height: 10),

                  // 2. Donate: https://gamerjagdish.com/donate
                  InkWell(
                    onTap: () => _openUrl(
                      context,
                      'https://gamerjagdish.com/donate',
                      'Donate',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Donate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'gamerjagdish.com/donate',
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
                  const SizedBox(height: 12),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                  const SizedBox(height: 10),

                  // 3. Check for update: github_release_apk_updater + shows current version
                  InkWell(
                    onTap: _isCheckingUpdate ? null : _handleCheckForUpdates,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.system_update_alt_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Check for Updates',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FutureBuilder<String>(
                                  future: UpdateService.getAppVersion(),
                                  builder: (context, snapshot) {
                                    final ver = snapshot.data ?? '1.2.0';
                                    return Text(
                                      'Version $ver',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_isCheckingUpdate)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                  const SizedBox(height: 10),

                  // 4. Changelog
                  InkWell(
                    onTap: () => UpdateService.showChangelog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.article_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Changelog',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'View release history',
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
                            size: 20,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                  const SizedBox(height: 10),

                  // 5. Source Code: https://github.com/GamerJagdish/cardminder
                  InkWell(
                    onTap: () => _openUrl(
                      context,
                      'https://github.com/GamerJagdish/cardminder',
                      'Source Code',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/logos/github.svg',
                              width: 19,
                              height: 19,
                              colorFilter: isDark
                                  ? const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn)
                                  : ColorFilter.mode(
                                      Theme.of(context).colorScheme.onSurface,
                                      BlendMode.srcIn,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Source Code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                  showAppSuccessSnackBar(
                    context,
                    title: 'Sync Completed',
                    message: 'Widget & Reminders synced successfully!',
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
    ),
    if (_showClownRain)
      _ClownRainOverlay(
        onDismiss: () => setState(() {
          _showClownRain = false;
          _developerClickCount = 0;
        }),
      ),
  ],
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
        child: Container(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(
              color: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
              width: 1.5,
            ),
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

class _ClownRainOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const _ClownRainOverlay({required this.onDismiss});

  @override
  State<_ClownRainOverlay> createState() => _ClownRainOverlayState();
}

class _ClownRainOverlayState extends State<_ClownRainOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ClownParticle> _clowns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _clowns = List.generate(40, (index) {
      final randomX = ((index * 73 + 29) % 100) / 100.0;
      final size = 22.0 + ((index * 17) % 28);
      final speedMultiplier = 0.8 + ((index * 19) % 15) / 10.0;
      final offsetPhase = ((index * 23) % 100) / 100.0;

      return _ClownParticle(
        relativeX: randomX,
        size: size,
        speedMultiplier: speedMultiplier,
        offsetPhase: offsetPhase,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final screenWidth = MediaQuery.of(context).size.width;

                  return Stack(
                    children: _clowns.map((clown) {
                      final progress =
                          (_controller.value * clown.speedMultiplier + clown.offsetPhase) % 1.0;
                      final topY = progress * (screenHeight + 100) - 50;
                      final leftX = clown.relativeX * (screenWidth - clown.size);

                      return Positioned(
                        top: topY,
                        left: leftX,
                        child: Text(
                          '🤡',
                          style: TextStyle(fontSize: clown.size),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🤡',
                          style: TextStyle(fontSize: 54),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "yes that's me a clown. laugh on me bro :)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.onDismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Close 🤡',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _ClownParticle {
  final double relativeX;
  final double size;
  final double speedMultiplier;
  final double offsetPhase;

  _ClownParticle({
    required this.relativeX,
    required this.size,
    required this.speedMultiplier,
    required this.offsetPhase,
  });
}
