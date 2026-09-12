import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/backup/restore_confirm_dialog.dart';
import '../widgets/backup/set_backup_pin_dialog.dart';
import '../widgets/backup/unlock_backup_pin_dialog.dart';
import '../widgets/special_effect.dart';
import 'settings/sections/about_settings_section.dart';
import 'settings/sections/appearance_section.dart';
import 'settings/sections/backup_settings_section.dart';
import 'settings/sections/notifications_settings_section.dart';
import 'settings/sections/widget_settings_section.dart';
import 'settings/widgets/debug_notification_tools.dart';
import 'settings/widgets/settings_section_header.dart';

/// Screen allowing the user to configure app appearance, widget preferences,
/// reminder intervals, encrypted backups, app updates, and developer diagnostics.
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
      ref.read(settingsNotifierProvider.notifier).updateSettings(
            newSettings,
            cards,
          );
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
                  AppearanceSection(
                    settings: settings,
                    onUpdateSettings: update,
                  ),
                  const SizedBox(height: 28),

                // SECTION 1: HOME SCREEN WIDGET
                WidgetSettingsSection(
                  settings: settings,
                  onUpdateSettings: update,
                ),
                const SizedBox(height: 28),

                // SECTION 2: NOTIFICATION PREFERENCES
                NotificationsSettingsSection(
                  settings: settings,
                  onUpdateSettings: update,
                ),
                const SizedBox(height: 28),

                // SECTION 3: DATA & BACKUP
                BackupSettingsSection(
                  settings: settings,
                  onUpdateSettings: update,
                  onChangeBackupLocation: () => _handleChangeBackupLocation(
                    context,
                    settings,
                    cards,
                  ),
                  onCreateBackup: () => _showCreateBackupPinDialog(
                    context,
                    cards,
                    settings,
                  ),
                  onRestoreBackup: () => SettingsScreen.handleRestoreBackup(
                    context,
                    ref,
                    settings,
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION 4: ABOUT
                AboutSettingsSection(
                  developerClickCount: _developerClickCount,
                  isCheckingUpdate: _isCheckingUpdate,
                  onDeveloperTap: _handleDeveloperTap,
                  onCheckForUpdates: _handleCheckForUpdates,
                  onOpenUrl: (url, label) => _openUrl(context, url, label),
                ),
                const SizedBox(height: 28),

                // SECTION 5: DEVELOPER DIAGNOSTICS (Debug mode only)
                if (kDebugMode) ...[
                  const SettingsSectionHeader(
                    title: 'DEBUG: NOTIFICATION TOOLS',
                    icon: Icons.bug_report_outlined,
                  ),
                  const SizedBox(height: 12),
                  const DebugNotificationTools(),
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

        // Clown Rain Easter Egg Overlay
          if (_showClownRain)
            SpecialEffectOverlay(
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
