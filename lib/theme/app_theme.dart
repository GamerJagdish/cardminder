import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF0F172A); // Deep slate midnight
  static const Color surfaceDark = Color(0xFF1E293B); // Elevated slate surface
  static const Color cardDark = Color(0xFF334155); // Card container
  static const Color primaryViolet = Color(0xFF8B5CF6); // Electric violet
  static const Color secondaryCyan = Color(0xFF06B6D4); // Cyan glow
  static const Color accentGold = Color(0xFFF59E0B); // Metallic gold
  static const Color accentEmerald = Color(0xFF10B981); // Emerald green
  static const Color accentRose = Color(0xFFF43F5E); // Bright rose red

  // Preset credit card gradient themes
  static const List<List<Color>> cardGradients = [
    [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC084FC)], // Deep Purple & Indigo
    [Color(0xFF0284C7), Color(0xFF0D9488), Color(0xFF10B981)], // Oceanic Teal
    [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)], // Brushed Gold & Bronze
    [Color(0xFFBE123C), Color(0xFFE11D48), Color(0xFFFB7185)], // Midnight Crimson
    [Color(0xFF1E293B), Color(0xFF475569), Color(0xFF64748B)], // Titanium Gray & Charcoal
    [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)], // Emerald Mint
    [Color(0xFF9333EA), Color(0xFFC084FC), Color(0xFFF472B6)], // Cosmic Pink & Purple
    [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)], // Sapphire Blue
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: ColorScheme.dark(
        primary: primaryViolet,
        secondary: secondaryCyan,
        surface: surfaceDark,
        error: accentRose,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgDark.withValues(alpha: 0.6),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryViolet, width: 2),
        ),
      ),
    );
  }
}
