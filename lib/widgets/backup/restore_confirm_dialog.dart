import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';
import '../common/responsive_dialog.dart';

/// Dialog to preview decrypted backup data and confirm restore.
class RestoreConfirmDialog extends StatelessWidget {
  final BackupData backupData;

  const RestoreConfirmDialog({super.key, required this.backupData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final verticalPadding =
        isLandscape || mediaQuery.size.height < 500 ? 16.0 : 24.0;

    return ResponsiveDialog(
      minWidth: 320,
      maxWidth: 440,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.32 : 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restore_rounded,
                      color: AppTheme.accentEmerald,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore Backup?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review backup contents',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMuted : AppTheme.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Backup Details Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.colors.border,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    context,
                    icon: Icons.credit_card_rounded,
                    label: 'Cards in Backup',
                    value: '${backupData.cards.length} cards',
                    valueColor: AppTheme.accentEmerald,
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Created On',
                    value: DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(backupData.exportDate),
                  ),
                  if (backupData.settings.userName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Account Name',
                      value: backupData.settings.userName,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Warning Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentAmber.withValues(alpha: isDark ? 0.32 : 0.22),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentAmber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restoring will overwrite your current card list and settings with this backup.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentEmerald,
                        foregroundColor: AppTheme.surfaceWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Restore Now',
                        style: TextStyle(
                          color: AppTheme.surfaceWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
