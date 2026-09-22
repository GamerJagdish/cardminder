import 'package:flutter/material.dart';

enum ShaderType {
  none,
  topographic,
  topographicIsolines,
  balatro,
  chessGlitch,
  amogus,
}

class AppThemePreset {
  final String id;
  final String name;
  final String description;
  final ShaderType shaderType;
  final String shaderAsset;
  final Color lineColor;
  final Color bgColor;
  final Color accentColor;
  final bool isDark;
  final List<AppThemePreset> variants;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.shaderType,
    required this.shaderAsset,
    required this.lineColor,
    required this.bgColor,
    required this.accentColor,
    this.isDark = true,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  IconData get icon {
    switch (shaderType) {
      case ShaderType.none:
        return Icons.smartphone_rounded;
      case ShaderType.topographic:
        return Icons.waves_rounded;
      case ShaderType.topographicIsolines:
        return Icons.gesture_rounded;
      case ShaderType.balatro:
        return Icons.style_rounded;
      case ShaderType.chessGlitch:
        return Icons.grid_view_rounded;
      case ShaderType.amogus:
        return Icons.pest_control_rounded;
    }
  }
}

class ThemePresets {
  static const String defaultPresetId = 'classic';

  // Sub-variants for Waveform (Topographic Waves)
  static const List<AppThemePreset> topographicVariants = [
    AppThemePreset(
      id: 'crimson_ruby',
      name: 'Ruby Waveform',
      description: 'Rich dark burgundy illuminated by laser ruby contours',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFFEF4444),
      bgColor: Color(0xFF14070A),
      accentColor: Color(0xFFF43F5E),
      isDark: true,
    ),
    AppThemePreset(
      id: 'gold_topo',
      name: 'Gold Waveform',
      description: 'Elegantly contoured golden isolines on midnight black',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFFEAB308),
      bgColor: Color(0xFF080B11),
      accentColor: Color(0xFFF59E0B),
      isDark: true,
    ),
    AppThemePreset(
      id: 'aurora_emerald',
      name: 'Emerald Waveform',
      description: 'Ethereal northern lights flowing in emerald & mint waves',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFF10B981),
      bgColor: Color(0xFF05120E),
      accentColor: Color(0xFF34D399),
      isDark: true,
    ),
    AppThemePreset(
      id: 'cosmic_violet',
      name: 'Violet Waveform',
      description: 'Deep space contours drenched in electric indigo',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFF0C0A1E),
      accentColor: Color(0xFFA78BFA),
      isDark: true,
    ),
    AppThemePreset(
      id: 'cyberpunk_cyan',
      name: 'Cyan Waveform',
      description: 'High-tech neon cyan isolines cutting through dark slate',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFF06B6D4),
      bgColor: Color(0xFF060E18),
      accentColor: Color(0xFF38BDF8),
      isDark: true,
    ),
    AppThemePreset(
      id: 'amoled_stealth',
      name: 'Stealth Waveform',
      description: '100% pure black OLED canvas with minimalist silver contours',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFF94A3B8),
      bgColor: Color(0xFF000000),
      accentColor: Color(0xFFE2E8F0),
      isDark: true,
    ),
    AppThemePreset(
      id: 'arctic_light',
      name: 'Pearl Waveform',
      description: 'Crisp porcelain canvas with subtle slate topographic waves',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFF94A3B8),
      bgColor: Color(0xFFF8FAFC),
      accentColor: Color(0xFF64748B),
      isDark: false,
    ),
  ];

  // Sub-variants for Silly Strings (Contour Elevation)
  static const List<AppThemePreset> sillyStringsVariants = [
    AppThemePreset(
      id: 'silly_strings',
      name: 'Silly Noir',
      description: 'Deep obsidian black canvas with crisp silver isoline ribbons',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFFE2E8F0),
      bgColor: Color(0xFF000000),
      accentColor: Color(0xFF94A3B8),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_cyan',
      name: 'Silly Cyan',
      description: 'Luminescent neon cyan isolines flowing across deep navy slate',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFF06B6D4),
      bgColor: Color(0xFF041019),
      accentColor: Color(0xFF38BDF8),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_emerald',
      name: 'Silly Emerald',
      description: 'High-frequency bio-green contours gliding over dark matrix abyss',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFF10B981),
      bgColor: Color(0xFF030D08),
      accentColor: Color(0xFF34D399),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_amber',
      name: 'Silly Amber',
      description: 'Radiant molten gold strings drifting across midnight obsidian',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFFF59E0B),
      bgColor: Color(0xFF140A03),
      accentColor: Color(0xFFFBBF24),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_violet',
      name: 'Silly Violet',
      description: 'Deep synthwave violet isolines rippling through dark cosmos',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFF0D0A1C),
      accentColor: Color(0xFFA78BFA),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_crimson',
      name: 'Silly Crimson',
      description: 'Fiery neon ruby lines winding through smoky crimson dark',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFFF43F5E),
      bgColor: Color(0xFF14050A),
      accentColor: Color(0xFFFB7185),
      isDark: true,
    ),
    AppThemePreset(
      id: 'silly_strings_pearl',
      name: 'Silly Pearl',
      description: 'Clean porcelain light canvas etched with delicate slate ribbons',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFF64748B),
      bgColor: Color(0xFFF8FAFC),
      accentColor: Color(0xFF475569),
      isDark: false,
    ),
  ];

  static const List<AppThemePreset> all = [
    // 1. Classic CardMinder
    AppThemePreset(
      id: 'classic',
      name: 'Classic CardMinder',
      description: 'The original clean minimalist look',
      shaderType: ShaderType.none,
      shaderAsset: '',
      lineColor: Color(0xFF38BDF8),
      bgColor: Colors.transparent,
      accentColor: Color(0xFF0284C7),
      isDark: true,
    ),
    // 2. Waveform (7 Variants)
    AppThemePreset(
      id: 'crimson_ruby',
      name: 'Waveform',
      description: 'Rich dark burgundy illuminated by laser ruby contours',
      shaderType: ShaderType.topographic,
      shaderAsset: 'shaders/topographic_lines.frag',
      lineColor: Color(0xFFEF4444),
      bgColor: Color(0xFF14070A),
      accentColor: Color(0xFFF43F5E),
      isDark: true,
      variants: topographicVariants,
    ),
    // 3. Silly Strings (7 Variants)
    AppThemePreset(
      id: 'silly_strings',
      name: 'Silly Strings',
      description: 'Organic procedural noodle ribbons weaving through harmonic contours',
      shaderType: ShaderType.topographicIsolines,
      shaderAsset: 'shaders/topograhic_lines_2.frag',
      lineColor: Color(0xFFE2E8F0),
      bgColor: Color(0xFF000000),
      accentColor: Color(0xFF94A3B8),
      isDark: true,
      variants: sillyStringsVariants,
    ),
    // 4. Chess Glitch
    AppThemePreset(
      id: 'chess_matrix',
      name: 'Chess Glitch',
      description: 'Retro matrix glitch and grid distortion of chessboard',
      shaderType: ShaderType.chessGlitch,
      shaderAsset: 'shaders/chess_glitch.frag',
      lineColor: Color(0xFFE2E8F0),
      bgColor: Color(0xFF000000),
      accentColor: Color(0xFF94A3B8),
      isDark: true,
    ),
    // 5. Balatro
    AppThemePreset(
      id: 'balatro_casino',
      name: 'Balatro',
      description: 'Hypnotic CRT effect from The Balatro Game',
      shaderType: ShaderType.balatro,
      shaderAsset: 'shaders/balatro.frag',
      lineColor: Color(0xFFE11D48),
      bgColor: Color(0xFF0F172A),
      accentColor: Color(0xFF38BDF8),
      isDark: true,
    ),
    // 6. RainGus
    AppThemePreset(
      id: 'rainbow_crew',
      name: 'RainGus',
      description: 'Trippy kaleidoscopic rainbow grid of animated crewmates',
      shaderType: ShaderType.amogus,
      shaderAsset: 'shaders/raingus.frag',
      lineColor: Color(0xFFA855F7),
      bgColor: Color(0xFF090314),
      accentColor: Color(0xFFC084FC),
      isDark: true,
    ),
    // 7. Sussy Glitch
    AppThemePreset(
      id: 'sus_glitch',
      name: 'Sussy Glitch',
      description: 'Glitchy chromatic aberration crewmates shift across a grid.',
      shaderType: ShaderType.amogus,
      shaderAsset: 'shaders/amoglitch.frag',
      lineColor: Color(0xFFEF4444),
      bgColor: Color(0xFF0B0F19),
      accentColor: Color(0xFFF87171),
      isDark: true,
    ),
    // 8. Abyssusy
    AppThemePreset(
      id: 'sus_abyss',
      name: 'Abyssusy',
      description: 'Hypnotic logarithmic spiral tunnel into the impostor void',
      shaderType: ShaderType.amogus,
      shaderAsset: 'shaders/amoghell.frag',
      lineColor: Color(0xFFF43F5E),
      bgColor: Color(0xFF0A000A),
      accentColor: Color(0xFFFB7185),
      isDark: true,
    ),
  ];

  static List<AppThemePreset> get allWithVariants {
    final list = <AppThemePreset>[];
    for (final p in all) {
      if (!list.any((existing) => existing.id == p.id)) {
        list.add(p);
      }
      for (final v in p.variants) {
        if (!list.any((existing) => existing.id == v.id)) {
          list.add(v);
        }
      }
    }
    return list;
  }

  static AppThemePreset getById(String id) {
    if (id == 'topo_contours') {
      return allWithVariants.firstWhere(
        (p) => p.id == 'silly_strings',
        orElse: () => all.first,
      );
    }
    return allWithVariants.firstWhere(
      (p) => p.id == id,
      orElse: () => all.first,
    );
  }

  /// Returns the parent preset from `all` if [presetId] is a variant, or the preset itself.
  static AppThemePreset findParentOrSelf(String presetId) {
    if (presetId == 'topo_contours') presetId = 'silly_strings';
    for (final parent in all) {
      if (parent.id == presetId) return parent;
      for (final variant in parent.variants) {
        if (variant.id == presetId) return parent;
      }
    }
    return all.first;
  }
}
