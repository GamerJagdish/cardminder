import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  static const List<Color> presetSwatches = [
    Color(0xFF0F172A), // Slate Dark
    Color(0xFF1E1B4B), // Midnight Indigo
    Color(0xFF065F46), // Deep Emerald
    Color(0xFF831843), // Rich Magenta
    Color(0xFF1E3A8A), // Ocean Navy
    Color(0xFF581C87), // Royal Violet
    Color(0xFF991B1B), // Crimson Red
    Color(0xFFB45309), // Amber Gold
    Color(0xFF15803D), // Forest Green
    Color(0xFF0284C7), // Sky Blue
    Color(0xFFBE185D), // Rose Pink
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
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
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
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
                      child: ColorPickerSlider(
                        TrackType.hue,
                        HSVColor.fromColor(Color(customRgbColorValue)),
                        (hsv) {
                          onColorChanged(hsv.toColor().toARGB32());
                        },
                        displayThumbColor: true,
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
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      crossFadeState: isVisible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }
}
