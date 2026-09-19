import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  static const Color bgLight = Color(0xFFF8FAFC); // Clean light background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Crisp white surface
  static const Color primaryNavy = Color(0xFF0F172A); // Dark navy button / primary
  static const Color textMuted = Color(0xFF94A3B8); // Muted grey text
  static const Color pureBlack = Color(0xFF000000); // Pure black
  static const Color defaultCustomRgbCardColor = Color(0xFFE11D48); // Rose default custom RGB

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0B0F19); // Midnight dark background
  static const Color surfaceDark = Color(0xFF1E293B); // Dark slate card surface
  static const Color primaryAccentDark = Color(0xFFF8FAFC); // Solid light accent
  static const Color textMutedDark = Color(0xFF64748B); // Muted slate text in dark mode
  static const Color borderDark = Color(0xFF334155); // Border in dark mode

  static const Color accentRose = Color(0xFFEF4444); // Urgent red
  static const Color accentEmerald = Color(0xFF10B981); // Safe green
  static const Color accentAmber = Color(0xFFF59E0B); // Warning gold
  static const Color amber200 = Color(0xFFFDE68A); // Amber 200 / clown hint text
  static const Color accentSky = Color(0xFF38BDF8); // Info sky blue

  // Extended Palette Constants
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Status Badges (Light and Dark specific)
  static const Color badgeSafeBgLight = Color(0xFFDCFCE7);
  static const Color badgeSafeFgLight = Color(0xFF065F46);
  static const Color badgeSafeBgDark = Color(0xFF064E3B);
  static const Color badgeSafeFgDark = Color(0xFF34D399);

  static const Color badgeWarningBgLight = Color(0xFFFEF3C7);
  static const Color badgeWarningFgLight = Color(0xFF92400E);
  static const Color badgeWarningBgDark = Color(0xFF78350F);
  static const Color badgeWarningFgDark = Color(0xFFFCD34D);
  static const Color badgeWarningTextDark = Color(0xFFFDE047);

  static const Color badgeUrgentBgLight = Color(0xFFFEE2E2);
  static const Color badgeUrgentFgLight = Color(0xFF991B1B);
  static const Color badgeUrgentBgDark = Color(0xFF7F1D1D);
  static const Color badgeUrgentFgDark = Color(0xFFFCA5A5);

  static const Color badgeNeutralBgLight = Color(0xFFF3F4F6);
  static const Color badgeNeutralFgLight = Color(0xFF6B7280);
  static const Color badgeNeutralBgDark = Color(0xFF1E293B);
  static const Color badgeNeutralFgDark = Color(0xFF94A3B8);

  // Domain Palettes:
  static const List<Color> paletteSwatches = [
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

  static const List<Color> emvChipMetallic = [
    Color(0xFFFFE27D),
    Color(0xFFE5B53B),
    Color(0xFFCC9928),
    Color(0xFFE2C470),
  ];
  static const Color emvChipBorder = Color(0xFF9E781C);
  static const Color emvChipTrace = Color(0xFF6B4E08);

  static const List<Color> confettiColors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  static const Color changelogBreaking = Color(0xFFF43F5E);
  static const Color changelogFeature = Color(0xFF38BDF8);
  static const Color changelogRefactor = Color(0xFFA78BFA);
  static const Color changelogFix = Color(0xFF94A3B8);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static AppColors colors(BuildContext context) => context.colors;

  // Preset credit card solid / gradient themes matching screenshot
  static const List<List<Color>> cardThemes = [
    [Color(0xFF273B66), Color(0xFF1E293B)], // Navy (Default)
    [Color(0xFF1D4ED8), Color(0xFF1E40AF)], // Deep Royal Blue
    [Color(0xFF15803D), Color(0xFF166534)], // Forest Green
    [Color(0xFF991B1B), Color(0xFF7F1D1D)], // Rust Crimson
    [Color(0xFF581C87), Color(0xFF4C1D95)], // Deep Purple
    [Color(0xFF334155), Color(0xFF1E293B)], // Slate Charcoal
  ];

  static List<Color> getCardColors(int colorIndex) {
    if (colorIndex >= 0 && colorIndex < cardThemes.length) {
      return cardThemes[colorIndex];
    }
    // Custom RGB Color (stored as 32-bit ARGB int)
    final baseColor = Color(colorIndex);
    final HSLColor hsl = HSLColor.fromColor(baseColor);
    final darkerColor =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    return [baseColor, darkerColor];
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: primaryNavy,
        surface: surfaceWhite,
        error: accentRose,
      ),
      extensions: const [
        AppColors.light,
      ],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryNavy,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate50,
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccentDark,
        secondary: primaryAccentDark,
        surface: surfaceDark,
        error: accentRose,
      ),
      extensions: const [
        AppColors.dark,
      ],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryAccentDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryAccentDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate900,
        hintStyle: TextStyle(color: textMutedDark.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAccentDark, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
