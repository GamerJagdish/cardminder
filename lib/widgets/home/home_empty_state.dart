import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../screens/add_edit_card_screen.dart';
import '../../screens/settings_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';

class HomeEmptyState extends ConsumerWidget {
  final AppSettings settings;
  final ValueChanged<String>? onCardAdded;

  const HomeEmptyState({
    super.key,
    required this.settings,
    this.onCardAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Cards Tracked Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your credit cards to track the 365-day deactivation countdown!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final addedCardId = await Navigator.push<String?>(
                  context,
                  slideUpRoute(const AddEditCardScreen()),
                );
                if (addedCardId != null && context.mounted) {
                  onCardAdded?.call(addedCardId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.primaryAccentDark
                    : AppTheme.primaryNavy,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Add First Card',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                final restored = await SettingsScreen.handleRestoreBackup(
                  context,
                  ref,
                  settings,
                );
                if (restored && context.mounted) {
                  HapticFeedback.mediumImpact();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Restore from Backup',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
