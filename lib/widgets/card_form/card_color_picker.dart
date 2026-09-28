import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../theme/app_theme.dart';

/// Interactive custom RGB color picker widget featuring hue slider,
/// real-time square color preview, editable hex code badge, and preset swatches.
class CardColorPicker extends StatefulWidget {
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
  State<CardColorPicker> createState() => _CardColorPickerState();
}

class _CardColorPickerState extends State<CardColorPicker> {
  late final TextEditingController _hexController;
  late final FocusNode _hexFocusNode;

  static String _formatHex(int colorValue) {
    return '#${Color(colorValue).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(
      text: _formatHex(widget.customRgbColorValue),
    );
    _hexFocusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CardColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customRgbColorValue != oldWidget.customRgbColorValue) {
      final formatted = _formatHex(widget.customRgbColorValue);
      if (_hexController.text.toUpperCase() != formatted) {
        _hexController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _hexFocusNode.removeListener(_onFocusChanged);
    _hexFocusNode.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (!_hexFocusNode.hasFocus) {
      _commitHexInput();
    }
    setState(() {});
  }

  void _onHexTextChanged(String value) {
    final hex = value.replaceFirst('#', '').trim();
    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        final newColor = 0xFF000000 | parsed;
        if (newColor != widget.customRgbColorValue) {
          widget.onColorChanged(newColor);
        }
      }
    }
  }

  void _commitHexInput() {
    final hex = _hexController.text.replaceFirst('#', '').trim().toUpperCase();
    if (hex.length == 3) {
      final expanded =
          '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      final parsed = int.tryParse(expanded, radix: 16);
      if (parsed != null) {
        final newColor = 0xFF000000 | parsed;
        _hexController.value = TextEditingValue(
          text: '#$expanded',
          selection: const TextSelection.collapsed(offset: 7),
        );
        if (newColor != widget.customRgbColorValue) {
          widget.onColorChanged(newColor);
        }
        return;
      }
    } else if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        final newColor = 0xFF000000 | parsed;
        if (newColor != widget.customRgbColorValue) {
          widget.onColorChanged(newColor);
        }
        return;
      }
    }

    // Restore valid hex if incomplete when focus is lost
    final currentValidHex = _formatHex(widget.customRgbColorValue);
    if (_hexController.text != currentValidHex) {
      _hexController.value = TextEditingValue(
        text: currentValidHex,
        selection: TextSelection.collapsed(offset: currentValidHex.length),
      );
    }
  }

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
      child: widget.isVisible
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
                      // Header with Title and Editable Hex Code Badge
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
                          // Editable Hex Value Display Badge
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF161B22)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hexFocusNode.hasFocus
                                    ? Theme.of(context).colorScheme.primary
                                    : context.colors.border,
                                width: _hexFocusNode.hasFocus ? 1.5 : 1.0,
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 76),
                              child: IntrinsicWidth(
                                child: TextField(
                                  key: const ValueKey('hex_color_input'),
                                  controller: _hexController,
                                  focusNode: _hexFocusNode,
                                  textAlign: TextAlign.center,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.done,
                                  cursorColor:
                                      Theme.of(context).colorScheme.primary,
                                  cursorWidth: 1.5,
                                  inputFormatters: [
                                    _HexColorInputFormatter(),
                                  ],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    letterSpacing: 1,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    counterText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  onChanged: _onHexTextChanged,
                                  onSubmitted: (_) => _commitHexInput(),
                                  onTapOutside: (_) {
                                    if (_hexFocusNode.hasFocus) {
                                      _hexFocusNode.unfocus();
                                    }
                                  },
                                ),
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
                            HSVColor.fromColor(Color(widget.customRgbColorValue)),
                            (hsv) {
                              if (_hexFocusNode.hasFocus) {
                                _hexFocusNode.unfocus();
                              }
                              widget.onColorChanged(hsv.toColor().toARGB32());
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
                              color: Color(widget.customRgbColorValue),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.slate600
                                    : AppTheme.slate300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(widget.customRgbColorValue)
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
                                    HSVColor.fromColor(
                                        Color(widget.customRgbColorValue)),
                                    (hsv) {
                                      if (_hexFocusNode.hasFocus) {
                                        _hexFocusNode.unfocus();
                                      }
                                      widget.onColorChanged(
                                          hsv.toColor().toARGB32());
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
                        children: CardColorPicker.presetSwatches.map((swatch) {
                          final isSelected =
                              widget.customRgbColorValue == swatch.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              if (_hexFocusNode.hasFocus) {
                                _hexFocusNode.unfocus();
                              }
                              widget.onColorChanged(swatch.toARGB32());
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

class _HexColorInputFormatter extends TextInputFormatter {
  static final RegExp _nonHexRegex = RegExp(r'[^0-9a-fA-F]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final hexOnly = newValue.text.replaceAll(_nonHexRegex, '').toUpperCase();
    final clamped = hexOnly.length > 6 ? hexOnly.substring(0, 6) : hexOnly;
    final formatted = '#$clamped';

    final rawCursor = newValue.selection.end;
    final textBeforeCursor = rawCursor > 0
        ? newValue.text.substring(0, rawCursor.clamp(0, newValue.text.length))
        : '';
    final hexBeforeCursor = textBeforeCursor
        .replaceAll(_nonHexRegex, '')
        .length
        .clamp(0, clamped.length);
    final cursorOffset = 1 + hexBeforeCursor;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
