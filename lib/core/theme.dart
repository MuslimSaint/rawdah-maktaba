import 'package:flutter/material.dart';

/// App color palette for both light and dark modes.
/// Green is the dominant identity color, gold is the accent.
class AppColors {
  final bool isDark;

  const AppColors({required this.isDark});

  // Backgrounds
  Color get bg => isDark ? const Color(0xFF2B342D) : const Color(0xFFE4EFE7);
  Color get card => isDark ? const Color(0xFF353F38) : const Color(0xFFF4F9F5);
  Color get surface2 => isDark ? const Color(0xFF3E4A42) : const Color(0xFFD8E8DC);

  // Brand (Cadmium Green)
  Color get brand => isDark ? const Color(0xFF1B9975) : const Color(0xFF005C46);
  Color get brandHover => isDark ? const Color(0xFF22C88A) : const Color(0xFF004B39);

  // Gold accent (Pastel Gold)
  Color get gold => const Color(0xFFFADCAC);
  Color get goldText => isDark ? const Color(0xFFE0B860) : const Color(0xFFC4982A);
  Color get goldLine => isDark
      ? const Color(0xFFFADCAC).withOpacity(0.25)
      : const Color(0xFFFADCAC).withOpacity(0.5);

  // Text
  Color get textPrimary => isDark ? const Color(0xFFE4EFE7) : const Color(0xFF0B1A13);
  Color get textSecondary => isDark ? const Color(0xFFB0C4B4) : const Color(0xFF2A4535);
  Color get textMuted => isDark ? const Color(0xFF859C8C) : const Color(0xFF5C7A68);
  Color get textFaint => isDark ? const Color(0xFF607566) : const Color(0xFF8FA396);

  // Danger
  Color get danger => isDark ? const Color(0xFFE06060) : const Color(0xFFB84040);
  Color get dangerBg => isDark ? const Color(0xFF4A2525) : const Color(0xFFFFF0F0);

  // Dividers
  Color get divider => isDark
      ? const Color(0xFFE4EFE7).withOpacity(0.1)
      : const Color(0xFF005C46).withOpacity(0.12);

  // Splash screen (always dark green regardless of theme)
  Color get splash => isDark ? const Color(0xFF0A1810) : const Color(0xFF013220);
  Color get splashGold => const Color(0xFFFADCAC);
  Color get splashText => const Color(0xFFE4EFE7);
}

/// App text styles helper.
/// Provides consistent typography with proper Arabic font handling.
class AppText {
  /// Arabic text style — always uses Amiri font with letterSpacing 0
  /// to prevent broken letter shaping on Android.
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

  /// Latin text style (English/Amharic) — uses system font.
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

  /// Small uppercase label (e.g. "AUTHOR", "APPEARANCE")
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
    fontFamily: null, // We handle fonts manually via AppText
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
