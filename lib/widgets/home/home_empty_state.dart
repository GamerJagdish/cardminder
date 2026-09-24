import 'dart:ui' as ui;
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20.0,
          16.0,
          20.0,
          16.0 + 64.0 + MediaQuery.paddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 30.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161B26).withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Frosted Glass Top Logo Orb
                    ClipOval(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.70),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.credit_card_off_outlined,
                              size: 44,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Title
                    Text(
                      'No Cards Tracked Yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        shadows: AppTheme.textShadowAmbient(isDark),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. High-Visibility Description
                    Text(
                      'Never let a credit card deactivate again. Add your first card or restore an encrypted backup to start tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                        shadows: AppTheme.textShadowAmbient(isDark),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // 4. Button 1: Add First Card (Frosted Pill, 54px, 16px text)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ElevatedButton(
                              onPressed: () async {
                                final addedCardId =
                                    await Navigator.push<String?>(
                                  context,
                                  slideUpRoute(const AddEditCardScreen()),
                                );
                                if (addedCardId != null && context.mounted) {
                                  onCardAdded?.call(addedCardId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.buttonPrimaryBg
                                    .withValues(alpha: isDark ? 0.90 : 0.92),
                                foregroundColor: context.colors.buttonPrimaryFg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Add First Card',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.colors.buttonPrimaryFg,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Button 2: Restore from Backup (Frosted Pill, 54px, 16px text)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                final restored =
                                    await SettingsScreen.handleRestoreBackup(
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
                                        .withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.70),
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.14)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Restore from Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
