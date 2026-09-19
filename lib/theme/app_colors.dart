import 'package:flutter/material.dart';

/// Semantic design tokens for CardMinder.
///
/// Implemented as a Flutter [ThemeExtension] so that colors automatically adapt
/// between light and dark modes with support for animated transitions (`lerp`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // --- Surfaces & Wells ---
  final Color surfaceSubtle;
  final Color surfaceSubtleSecondary;
  final Color surfaceCard;
  final Color inputFill;
  final Color dialogBg;
  final Color containerFill;
  final Color containerBorder;
  final Color cardShadow;
  final Color handleBar;

  // --- Borders & Dividers ---
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // --- Text & Icons ---
  final Color textPrimary;
  final Color textMuted;
  final Color textSubtle;

  // --- Buttons / Actions ---
  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryFg;
  final Color buttonGhostBg;
  final Color buttonGhostFg;
  final Color buttonMutedFg;
  final Color circleButtonBg;
  final Color editActionBg;
  final Color destructive;
  final Color destructiveFg;

  // --- Badges & Status ---
  final Color badgeSafeBg;
  final Color badgeSafeFg;
  final Color badgeWarningBg;
  final Color badgeWarningFg;
  final Color badgeUrgentBg;
  final Color badgeUrgentFg;
  final Color badgeInfoBg;
  final Color badgeInfoFg;
  final Color badgeNeutralBg;
  final Color badgeNeutralFg;

  // --- Snackbars ---
  final Color snackbarBg;
  final Color snackbarBorder;
  final Color snackbarText;
  final Color snackbarTextMuted;

  const AppColors({
    required this.surfaceSubtle,
    required this.surfaceSubtleSecondary,
    required this.surfaceCard,
    required this.inputFill,
    required this.dialogBg,
    required this.containerFill,
    required this.containerBorder,
    required this.cardShadow,
    required this.handleBar,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.textPrimary,
    required this.textMuted,
    required this.textSubtle,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryFg,
    required this.buttonGhostBg,
    required this.buttonGhostFg,
    required this.buttonMutedFg,
    required this.circleButtonBg,
    required this.editActionBg,
    required this.destructive,
    required this.destructiveFg,
    required this.badgeSafeBg,
    required this.badgeSafeFg,
    required this.badgeWarningBg,
    required this.badgeWarningFg,
    required this.badgeUrgentBg,
    required this.badgeUrgentFg,
    required this.badgeInfoBg,
    required this.badgeInfoFg,
    required this.badgeNeutralBg,
    required this.badgeNeutralFg,
    required this.snackbarBg,
    required this.snackbarBorder,
    required this.snackbarText,
    required this.snackbarTextMuted,
  });

  /// Design tokens for Light Mode.
  static const AppColors light = AppColors(
    surfaceSubtle: Color(0xFFF1F5F9), // Slate 100
    surfaceSubtleSecondary: Color(0xFFF8FAFC), // Slate 50
    surfaceCard: Color(0xFFFFFFFF), // Crisp white
    inputFill: Color(0xFFF8FAFC), // Slate 50
    dialogBg: Color(0xFFFFFFFF),
    containerFill: Color(0xFFE2E8F0), // Slate 200
    containerBorder: Color(0xFFE2E8F0), // Slate 200
    cardShadow: Color(0x05000000), // Colors.black @ 2% alpha
    handleBar: Color(0x2E000000), // Colors.black @ 18% alpha
    border: Color(0xFFE2E8F0), // Slate 200
    borderSubtle: Color(0xFFCBD5E1), // Slate 300
    divider: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A), // Slate 900
    textMuted: Color(0xFF94A3B8), // Slate 400
    textSubtle: Color(0xFF475569), // Slate 600
    buttonPrimaryBg: Color(0xFF0F172A), // Dark navy
    buttonPrimaryFg: Colors.white,
    buttonSecondaryBg: Color(0xFFF1F5F9), // Slate 100
    buttonSecondaryFg: Color(0xFF0F172A),
    buttonGhostBg: Color(0x08000000), // Colors.black @ 3% alpha
    buttonGhostFg: Color(0xFF64748B), // Slate 500
    buttonMutedFg: Color(0xFF475569), // Slate 600
    circleButtonBg: Color(0x14000000), // Colors.black @ 8% alpha
    editActionBg: Color(0xFF0F172A), // Dark navy
    destructive: Color(0xFFEF4444),
    destructiveFg: Colors.white,
    badgeSafeBg: Color(0xFFDCFCE7),
    badgeSafeFg: Color(0xFF065F46),
    badgeWarningBg: Color(0xFFFEF3C7),
    badgeWarningFg: Color(0xFF92400E),
    badgeUrgentBg: Color(0xFFFEE2E2),
    badgeUrgentFg: Color(0xFF991B1B),
    badgeInfoBg: Color(0x2638BDF8), // 0xFF38BDF8 @ 15% opacity
    badgeInfoFg: Color(0xFF0284C7),
    badgeNeutralBg: Color(0xFFF3F4F6),
    badgeNeutralFg: Color(0xFF6B7280),
    snackbarBg: Color(0xFF0F172A),
    snackbarBorder: Color(0xFF1E293B),
    snackbarText: Colors.white,
    snackbarTextMuted: Color(0xCCFFFFFF), // 80% opacity
  );

  /// Design tokens for Dark Mode.
  static const AppColors dark = AppColors(
    surfaceSubtle: Color(0xFF0F172A), // Slate 900
    surfaceSubtleSecondary: Color(0xFF1E293B), // Slate 800
    surfaceCard: Color(0xFF1E293B), // Dark slate
    inputFill: Color(0xFF0F172A), // Slate 900
    dialogBg: Color(0xFF1E293B),
    containerFill: Color(0xFF1E293B), // Slate 800
    containerBorder: Color(0xFF1E293B), // Slate 800
    cardShadow: Color(0x05000000), // Colors.black @ 2% alpha
    handleBar: Color(0x2EFFFFFF), // Colors.white @ 18% alpha
    border: Color(0xFF334155), // Slate 700
    borderSubtle: Color(0xFF334155),
    divider: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC), // Slate 50
    textMuted: Color(0xFF64748B), // Slate 500
    textSubtle: Color(0xFFCBD5E1), // Slate 300
    buttonPrimaryBg: Color(0xFFF8FAFC), // Light accent
    buttonPrimaryFg: Colors.black,
    buttonSecondaryBg: Color(0xFF0F172A),
    buttonSecondaryFg: Color(0xFFF8FAFC),
    buttonGhostBg: Color(0x0AFFFFFF), // Colors.white @ 4% alpha
    buttonGhostFg: Color(0xFF94A3B8), // Slate 400
    buttonMutedFg: Color(0xFF94A3B8), // Slate 400
    circleButtonBg: Color(0x1FFFFFFF), // Colors.white @ 12% alpha
    editActionBg: Color(0xFF334155), // Slate 700
    destructive: Color(0xFFEF4444),
    destructiveFg: Colors.white,
    badgeSafeBg: Color(0xFF064E3B),
    badgeSafeFg: Color(0xFF34D399),
    badgeWarningBg: Color(0xFF78350F),
    badgeWarningFg: Color(0xFFFCD34D),
    badgeUrgentBg: Color(0xFF7F1D1D),
    badgeUrgentFg: Color(0xFFFCA5A5),
    badgeInfoBg: Color(0x2638BDF8), // 0xFF38BDF8 @ 15% opacity
    badgeInfoFg: Color(0xFF38BDF8),
    badgeNeutralBg: Color(0xFF1E293B),
    badgeNeutralFg: Color(0xFF94A3B8),
    snackbarBg: Color(0xFF1E293B),
    snackbarBorder: Color(0xFF334155),
    snackbarText: Colors.white,
    snackbarTextMuted: Color(0xCCFFFFFF), // 80% opacity
  );

  @override
  AppColors copyWith({
    Color? surfaceSubtle,
    Color? surfaceSubtleSecondary,
    Color? surfaceCard,
    Color? inputFill,
    Color? dialogBg,
    Color? containerFill,
    Color? containerBorder,
    Color? cardShadow,
    Color? handleBar,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? textPrimary,
    Color? textMuted,
    Color? textSubtle,
    Color? buttonPrimaryBg,
    Color? buttonPrimaryFg,
    Color? buttonSecondaryBg,
    Color? buttonSecondaryFg,
    Color? buttonGhostBg,
    Color? buttonGhostFg,
    Color? buttonMutedFg,
    Color? circleButtonBg,
    Color? editActionBg,
    Color? destructive,
    Color? destructiveFg,
    Color? badgeSafeBg,
    Color? badgeSafeFg,
    Color? badgeWarningBg,
    Color? badgeWarningFg,
    Color? badgeUrgentBg,
    Color? badgeUrgentFg,
    Color? badgeInfoBg,
    Color? badgeInfoFg,
    Color? badgeNeutralBg,
    Color? badgeNeutralFg,
    Color? snackbarBg,
    Color? snackbarBorder,
    Color? snackbarText,
    Color? snackbarTextMuted,
  }) {
    return AppColors(
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceSubtleSecondary:
          surfaceSubtleSecondary ?? this.surfaceSubtleSecondary,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      inputFill: inputFill ?? this.inputFill,
      dialogBg: dialogBg ?? this.dialogBg,
      containerFill: containerFill ?? this.containerFill,
      containerBorder: containerBorder ?? this.containerBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      handleBar: handleBar ?? this.handleBar,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
      buttonPrimaryFg: buttonPrimaryFg ?? this.buttonPrimaryFg,
      buttonSecondaryBg: buttonSecondaryBg ?? this.buttonSecondaryBg,
      buttonSecondaryFg: buttonSecondaryFg ?? this.buttonSecondaryFg,
      buttonGhostBg: buttonGhostBg ?? this.buttonGhostBg,
      buttonGhostFg: buttonGhostFg ?? this.buttonGhostFg,
      buttonMutedFg: buttonMutedFg ?? this.buttonMutedFg,
      circleButtonBg: circleButtonBg ?? this.circleButtonBg,
      editActionBg: editActionBg ?? this.editActionBg,
      destructive: destructive ?? this.destructive,
      destructiveFg: destructiveFg ?? this.destructiveFg,
      badgeSafeBg: badgeSafeBg ?? this.badgeSafeBg,
      badgeSafeFg: badgeSafeFg ?? this.badgeSafeFg,
      badgeWarningBg: badgeWarningBg ?? this.badgeWarningBg,
      badgeWarningFg: badgeWarningFg ?? this.badgeWarningFg,
      badgeUrgentBg: badgeUrgentBg ?? this.badgeUrgentBg,
      badgeUrgentFg: badgeUrgentFg ?? this.badgeUrgentFg,
      badgeInfoBg: badgeInfoBg ?? this.badgeInfoBg,
      badgeInfoFg: badgeInfoFg ?? this.badgeInfoFg,
      badgeNeutralBg: badgeNeutralBg ?? this.badgeNeutralBg,
      badgeNeutralFg: badgeNeutralFg ?? this.badgeNeutralFg,
      snackbarBg: snackbarBg ?? this.snackbarBg,
      snackbarBorder: snackbarBorder ?? this.snackbarBorder,
      snackbarText: snackbarText ?? this.snackbarText,
      snackbarTextMuted: snackbarTextMuted ?? this.snackbarTextMuted,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceSubtleSecondary: Color.lerp(
          surfaceSubtleSecondary, other.surfaceSubtleSecondary, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
      containerFill: Color.lerp(containerFill, other.containerFill, t)!,
      containerBorder: Color.lerp(containerBorder, other.containerBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      handleBar: Color.lerp(handleBar, other.handleBar, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      buttonPrimaryBg:
          Color.lerp(buttonPrimaryBg, other.buttonPrimaryBg, t)!,
      buttonPrimaryFg:
          Color.lerp(buttonPrimaryFg, other.buttonPrimaryFg, t)!,
      buttonSecondaryBg:
          Color.lerp(buttonSecondaryBg, other.buttonSecondaryBg, t)!,
      buttonSecondaryFg:
          Color.lerp(buttonSecondaryFg, other.buttonSecondaryFg, t)!,
      buttonGhostBg: Color.lerp(buttonGhostBg, other.buttonGhostBg, t)!,
      buttonGhostFg: Color.lerp(buttonGhostFg, other.buttonGhostFg, t)!,
      buttonMutedFg: Color.lerp(buttonMutedFg, other.buttonMutedFg, t)!,
      circleButtonBg: Color.lerp(circleButtonBg, other.circleButtonBg, t)!,
      editActionBg: Color.lerp(editActionBg, other.editActionBg, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveFg: Color.lerp(destructiveFg, other.destructiveFg, t)!,
      badgeSafeBg: Color.lerp(badgeSafeBg, other.badgeSafeBg, t)!,
      badgeSafeFg: Color.lerp(badgeSafeFg, other.badgeSafeFg, t)!,
      badgeWarningBg: Color.lerp(badgeWarningBg, other.badgeWarningBg, t)!,
      badgeWarningFg: Color.lerp(badgeWarningFg, other.badgeWarningFg, t)!,
      badgeUrgentBg: Color.lerp(badgeUrgentBg, other.badgeUrgentBg, t)!,
      badgeUrgentFg: Color.lerp(badgeUrgentFg, other.badgeUrgentFg, t)!,
      badgeInfoBg: Color.lerp(badgeInfoBg, other.badgeInfoBg, t)!,
      badgeInfoFg: Color.lerp(badgeInfoFg, other.badgeInfoFg, t)!,
      badgeNeutralBg: Color.lerp(badgeNeutralBg, other.badgeNeutralBg, t)!,
      badgeNeutralFg: Color.lerp(badgeNeutralFg, other.badgeNeutralFg, t)!,
      snackbarBg: Color.lerp(snackbarBg, other.snackbarBg, t)!,
      snackbarBorder: Color.lerp(snackbarBorder, other.snackbarBorder, t)!,
      snackbarText: Color.lerp(snackbarText, other.snackbarText, t)!,
      snackbarTextMuted:
          Color.lerp(snackbarTextMuted, other.snackbarTextMuted, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] for clean, type-safe token access.
extension AppThemeContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light);
}
