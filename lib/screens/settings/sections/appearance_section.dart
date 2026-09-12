import 'package:flutter/material.dart';
import '../../../models/app_settings.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tiles.dart';

/// Section for configuring app theme appearance (System, Light, Dark).
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
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
              ThemeOptionTile(
                title: 'System',
                icon: Icons.phone_android_rounded,
                isSelected: settings.themeMode == 'system',
                onTap: () => onUpdateSettings(
                  settings.copyWith(themeMode: 'system'),
                ),
              ),
              const SizedBox(width: 8),
              ThemeOptionTile(
                title: 'Light',
                icon: Icons.wb_sunny_rounded,
                isSelected: settings.themeMode == 'light',
                onTap: () => onUpdateSettings(
                  settings.copyWith(themeMode: 'light'),
                ),
              ),
              const SizedBox(width: 8),
              ThemeOptionTile(
                title: 'Dark',
                icon: Icons.nightlight_round,
                isSelected: settings.themeMode == 'dark',
                onTap: () => onUpdateSettings(
                  settings.copyWith(themeMode: 'dark'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
