import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../theme/app_theme.dart';

/// Interactive custom RGB color picker widget featuring hue slider,
/// real-time square color preview, hex code badge, and preset swatches.
class CardColorPicker extends StatelessWidget {
  final int customRgbColorValue;
  final ValueChanged<int> onColorChanged;
  final bool isVisible;

  const CardColorPicker({
    super.key,
    required this.customRgbColorValue,
    required this.onColorChanged,
    required this.isVisible,
  });

  static const List<Color> presetSwatches = AppTheme.paletteSwatches;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? const Color(0xFF1E2430)
        : const Color(0xFFF1F5F9);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isVisible
          ? KeyedSubtree(
              key: const ValueKey('card_color_picker_visible'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title and Hex Code Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.palette_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Pick Your Color',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          // Hex Value Display Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF161B22)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.colors.border,
                              ),
                            ),
                            child: Text(
                              '#${Color(customRgbColorValue).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Color Picker Area
                      SizedBox(
                        width: double.infinity,
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ColorPickerArea(
                            HSVColor.fromColor(Color(customRgbColorValue)),
                            (hsv) {
                              onColorChanged(hsv.toColor().toARGB32());
                            },
                            PaletteType.hsvWithHue,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Slider & SQUARE Color Preview Row
                      Row(
                        children: [
                          // SQUARE Color Preview Container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(customRgbColorValue),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.slate600
                                    : AppTheme.slate300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(customRgbColorValue)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hue Slider
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth <= 20) {
                                    return const SizedBox.shrink();
                                  }
                                  return ColorPickerSlider(
                                    TrackType.hue,
                                    HSVColor.fromColor(Color(customRgbColorValue)),
                                    (hsv) {
                                      onColorChanged(hsv.toColor().toARGB32());
                                    },
                                    displayThumbColor: true,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Quick Preset Color Swatches
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: presetSwatches.map((swatch) {
                          final isSelected =
                              customRgbColorValue == swatch.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              onColorChanged(swatch.toARGB32());
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: swatch,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: isSelected ? 2.5 : 0,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: AppTheme.surfaceWhite, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(
              key: ValueKey('card_color_picker_hidden'),
            ),
    );
  }
}
