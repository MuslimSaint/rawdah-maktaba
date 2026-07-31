import 'package:flutter/material.dart';

/// App color palette for both light and dark modes.
class AppColors {
  final bool isDark;

  const AppColors({required this.isDark});

  // Backgrounds
  Color get bg =>
      isDark ? const Color(0xFF2B342D) : const Color(0xFFE4EFE7);
  Color get card =>
      isDark ? const Color(0xFF353F38) : const Color(0xFFF4F9F5);
  Color get surface2 =>
      isDark ? const Color(0xFF3E4A42) : const Color(0xFFD8E8DC);

  // Brand (Cadmium Green)
  Color get brand =>
      isDark ? const Color(0xFF1B9975) : const Color(0xFF005C46);
  Color get brandHover =>
      isDark ? const Color(0xFF22C88A) : const Color(0xFF004B39);

  // Gold accent (Pastel Gold)
  Color get gold => const Color(0xFFFADCAC);
  Color get goldText =>
      isDark ? const Color(0xFFE0B860) : const Color(0xFFC4982A);
  Color get goldLine => isDark
      ? const Color(0xFFFADCAC).withOpacity(0.25)
      : const Color(0xFFFADCAC).withOpacity(0.5);

  // Text
  Color get textPrimary =>
      isDark ? const Color(0xFFE4EFE7) : const Color(0xFF0B1A13);
  Color get textSecondary =>
      isDark ? const Color(0xFFB0C4B4) : const Color(0xFF2A4535);
  Color get textMuted =>
      isDark ? const Color(0xFF859C8C) : const Color(0xFF5C7A68);
  Color get textFaint =>
      isDark ? const Color(0xFF607566) : const Color(0xFF8FA396);

  // Danger
  Color get danger =>
      isDark ? const Color(0xFFE06060) : const Color(0xFFB84040);
  Color get dangerBg =>
      isDark ? const Color(0xFF4A2525) : const Color(0xFFFFF0F0);

  // Dividers
  Color get divider => isDark
      ? const Color(0xFFE4EFE7).withOpacity(0.1)
      : const Color(0xFF005C46).withOpacity(0.12);

  // Splash
  Color get splash =>
      isDark ? const Color(0xFF0A1810) : const Color(0xFF013220);
  Color get splashGold => const Color(0xFFFADCAC);
  Color get splashText => const Color(0xFFE4EFE7);
}

// ─── Spacing scale ───────────────────────────────────────
//
// Use these instead of raw numbers. Asymmetric application:
//   - Between tightly related elements (label → input): xs, sm
//   - Between cards in a list: sm, md
//   - Between unrelated sections: lg, xl, xxl
//
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Named gaps as SizedBox widgets for convenience
  static const Widget gapXs = SizedBox(height: AppSpacing.xs);
  static const Widget gapSm = SizedBox(height: AppSpacing.sm);
  static const Widget gapMd = SizedBox(height: AppSpacing.md);
  static const Widget gapBase = SizedBox(height: AppSpacing.base);
  static const Widget gapLg = SizedBox(height: AppSpacing.lg);
  static const Widget gapXl = SizedBox(height: AppSpacing.xl);

  static const Widget hGapXs = SizedBox(width: AppSpacing.xs);
  static const Widget hGapSm = SizedBox(width: AppSpacing.sm);
  static const Widget hGapMd = SizedBox(width: AppSpacing.md);
  static const Widget hGapBase = SizedBox(width: AppSpacing.base);
}

// ─── Radius tokens ───────────────────────────────────────
//
// Different component types get different radii:
//   card      → large (20–24px) — content cards, sheets
//   listItem  → medium (14px)   — list rows, compact cards
//   button    → small (11px)    — action buttons
//   input     → small (10px)    — text fields
//   pill      → full            — tags, badges, chips
//
class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double listItem = 14;
  static const double button = 11;
  static const double input = 10;
  static const double pill = 999;

  static BorderRadius get cardRadius =>
      BorderRadius.circular(card);
  static BorderRadius get listItemRadius =>
      BorderRadius.circular(listItem);
  static BorderRadius get buttonRadius =>
      BorderRadius.circular(button);
  static BorderRadius get inputRadius =>
      BorderRadius.circular(input);
  static BorderRadius get pillRadius =>
      BorderRadius.circular(pill);
}

/// App text styles helper.
class AppText {
  static TextStyle arabic({
    required Color color,
    double size = 15,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
      height: height,
    );
  }

  static TextStyle latin({
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label({required Color color}) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.2,
    );
  }
}

/// Builds the Flutter ThemeData from our AppColors.
ThemeData buildTheme(bool isDark) {
  final c = AppColors(isDark: isDark);

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.bg,
    primaryColor: c.brand,
    fontFamily: null,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.brand,
      onPrimary: Colors.white,
      secondary: c.gold,
      onSecondary: c.textPrimary,
      surface: c.card,
      onSurface: c.textPrimary,
      error: c.danger,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: c.textPrimary),
      bodyMedium: TextStyle(color: c.textPrimary),
      bodySmall: TextStyle(color: c.textMuted),
    ),
    iconTheme: IconThemeData(color: c.textPrimary),
    useMaterial3: true,
  );
}
