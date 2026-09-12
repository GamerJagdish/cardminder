import 'package:flutter/material.dart';
import '../../../models/app_settings.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tiles.dart';

/// Section for configuring Android home screen widget display filters and card count limits.
class WidgetSettingsSection extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onUpdateSettings;

  const WidgetSettingsSection({
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
                  return PillOption(
                    label: label,
                    isSelected: isSelected,
                    onTap: () => onUpdateSettings(
                      settings.copyWith(widgetMaxCards: count),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
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
                  PillOption(
                    label: 'All Cards',
                    isSelected: settings.widgetFilter == 'all',
                    onTap: () => onUpdateSettings(
                      settings.copyWith(widgetFilter: 'all'),
                    ),
                  ),
                  PillOption(
                    label: '< 90 Days',
                    isSelected:
                        settings.widgetFilter == 'warning_and_urgent',
                    onTap: () => onUpdateSettings(
                      settings.copyWith(widgetFilter: 'warning_and_urgent'),
                    ),
                  ),
                  PillOption(
                    label: '< 30 Days',
                    isSelected: settings.widgetFilter == 'action_needed',
                    onTap: () => onUpdateSettings(
                      settings.copyWith(widgetFilter: 'action_needed'),
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
