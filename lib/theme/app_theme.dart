import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgLight = Color(0xFFF8FAFC); // Clean light background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Crisp white surface
  static const Color primaryNavy = Color(0xFF0F172A); // Dark navy button / primary
  static const Color textMuted = Color(0xFF94A3B8); // Muted grey text
  static const Color textDark = Color(0xFF0F172A); // Dark text

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF0B0F19); // Midnight dark background
  static const Color surfaceDark = Color(0xFF1E293B); // Dark slate card surface
  static const Color primaryAccentDark = Color(0xFFF8FAFC); // Solid light accent
  static const Color textLight = Color(0xFFF8FAFC); // White/light text
  static const Color textMutedDark = Color(0xFF64748B); // Muted slate text in dark mode
  static const Color borderDark = Color(0xFF334155); // Border in dark mode

  static const Color accentRose = Color(0xFFEF4444); // Urgent red
  static const Color accentEmerald = Color(0xFF10B981); // Safe green
  static const Color accentAmber = Color(0xFFF59E0B); // Warning gold

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
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
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
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
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
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textLight,
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
        fillColor: const Color(0xFF0F172A),
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
