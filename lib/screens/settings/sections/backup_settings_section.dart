import 'package:flutter/material.dart';
import '../../../models/app_settings.dart';
import '../../../services/backup_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/snackbar_utils.dart';
import '../widgets/settings_section_header.dart';

/// Section for managing backup location storage, manual backups, and data restoration.
class BackupSettingsSection extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;
  final VoidCallback onChangeBackupLocation;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;

  const BackupSettingsSection({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
    required this.onChangeBackupLocation,
    required this.onCreateBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
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
                      onTap: onChangeBackupLocation,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
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
                                  onUpdateSettings(
                                    settings.copyWith(backupPath: ''),
                                  );
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
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
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
                'Backups are encrypted with your private PIN.',
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
                      onTap: onCreateBackup,
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
                      onTap: onRestoreBackup,
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
                              color: Theme.of(context).colorScheme.onSurface,
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
      ],
    );
  }
}
