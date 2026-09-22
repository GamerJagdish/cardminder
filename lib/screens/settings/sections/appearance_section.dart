import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/app_settings.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/page_transitions.dart';
import '../theme_preview_screen.dart';
import '../widgets/settings_section_header.dart';

/// Section providing entry point to the full-screen Revolut-style Theme & Background customization.
class AppearanceSection extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;

  const AppearanceSection({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  @override
  Widget build(BuildContext context) {
    final activePreset = ThemePresets.getById(settings.themePreset);
    final modeLabel = settings.themeMode[0].toUpperCase() + settings.themeMode.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          title: 'THEME & BACKGROUND',
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                slideUpRoute(const ThemePreviewScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Glowing Theme Preset Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activePreset.bgColor,
                      border: Border.all(
                        color: activePreset.lineColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activePreset.lineColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        activePreset.icon,
                        size: 22,
                        color: activePreset.lineColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Mode Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Theme & Background',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              activePreset.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: activePreset.lineColor,
                              ),
                            ),
                            const Text(
                              ' / ',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            Text(
                              modeLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Trailing Chevron
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.circleButtonBg,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
