
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette - Signature Colors
  static const Color brandColor = Color(0xFF7DE720); // Neon/Lime Green
  static const Color blackColor = Color(0xFF000000);
  
  static const Color primary = blackColor;
  static const Color surface = Color(0xFF1A1A1A); // Darker surface for dark mode feel
  static const Color cardBg = Color(0xFF121212);

  // Map accents to brand color
  static const Color hotelAccent = brandColor;
  static const Color hotelLight = Color(0x337DE720); // 20% opacity brand

  static const Color resortAccent = brandColor;
  static const Color resortLight = Color(0x337DE720); // 20% opacity brand

  static const Color guideGold = brandColor;
  static const Color guideLight = Color(0x337DE720);

  // Text Colors adapted for dark mode
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFF334155);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Light Theme Constants (For toggle)
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardBgLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color dividerLight = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: brandColor,
      scaffoldBackgroundColor: surfaceLight,
      colorScheme: const ColorScheme.light(
        primary: brandColor,
        secondary: brandColor,
        surface: surfaceLight,
        background: surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),
      cardTheme: CardTheme(
        color: cardBgLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: blackColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimaryLight),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimaryLight),
        bodyMedium: TextStyle(color: textSecondaryLight),
      ),
      dividerColor: dividerLight,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: brandColor,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: brandColor,
        secondary: brandColor,
        surface: surface,
        background: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: blackColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: brandColor),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: blackColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      dividerColor: divider,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: blackColor,
        selectedItemColor: brandColor,
        unselectedItemColor: textSecondary,
      )
    );
  }

  // Helper method to get theme-aware colors based on context
  static Color getCardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? cardBg : cardBgLight;
  static Color getSurfaceColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? surface : surfaceLight;
  static Color getTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? textPrimary : textPrimaryLight;
  static Color getSecondaryTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? textSecondary : textSecondaryLight;
  static Color getDividerColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? divider : dividerLight;
}
