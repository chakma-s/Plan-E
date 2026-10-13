import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette - Signature Colors matching Web Portal
  static const Color brandColor = Color(0xFF7DE720); // Neon/Lime Green (#7de720)
  static const Color blackColor = Color(0xFF000000);
  static const Color logoAccent = Color(0xFFF2C48C); // Warm caramel/amber for -E
  static const Color logoDark = Color(0xFF0B1324);   // Deep slate/navy for Light mode logo

  static const Color primary = blackColor;
  static const Color surface = Color(0xFF1A1A1A); // Dark mode inputs / chips (#1a1a1a)
  static const Color cardBg = Color(0xFF121212); // Dark mode card & header (#121212)
  static const Color scaffoldDark = Color(0xFF000000); // Dark mode pure black scaffold
  static const Color borderDark = Color(0xFF2A2A2A); // Dark mode card borders (#2a2a2a)
  static const Color inputBorderDark = Color(0xFF333333); // Dark mode input borders (#333333)

  // Map accents to brand color
  static const Color hotelAccent = brandColor;
  static const Color hotelLight = Color(0x337DE720); // 20% opacity brand

  static const Color resortAccent = brandColor;
  static const Color resortLight = Color(0x337DE720); // 20% opacity brand

  static const Color guideGold = brandColor;
  static const Color guideLight = Color(0x337DE720);

  // Text Colors adapted for dark mode
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color divider = Color(0xFF2A2A2A);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Light Theme Constants matching Web Portal Tailwind palette
  static const Color scaffoldLight = Color(0xFFF8FAFC); // Slate 50 (#f8fafc)
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white for search & cards
  static const Color segmentedBgLight = Color(0xFFF1F5F9); // Slate 100 for segmented tabs (#f1f5f9)
  static const Color cardBgLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200 (#e2e8f0)
  static const Color inputBorderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900 (#0f172a)
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500 (#64748b)
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400 (#94a3b8)
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color brandTextLight = Color(0xFF065F46); // Emerald 800 for high-contrast green text

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: brandColor,
      scaffoldBackgroundColor: scaffoldLight,
      colorScheme: const ColorScheme.light(
        primary: brandColor,
        secondary: brandColor,
        surface: cardBgLight,
        onSurface: textPrimaryLight,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        baseTextTheme.copyWith(
          bodyLarge: const TextStyle(color: textPrimaryLight),
          bodyMedium: const TextStyle(color: textSecondaryLight),
          titleMedium: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'Plus Jakarta Sans',
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: cardBgLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: blackColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimaryLight),
      dividerColor: dividerLight,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brandTextLight,
        unselectedItemColor: textMutedLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: brandColor,
      scaffoldBackgroundColor: scaffoldDark,
      colorScheme: const ColorScheme.dark(
        primary: brandColor,
        secondary: brandColor,
        surface: cardBg,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        baseTextTheme.copyWith(
          bodyLarge: const TextStyle(color: textPrimary),
          bodyMedium: const TextStyle(color: textSecondary),
          titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'Plus Jakarta Sans',
        ),
        iconTheme: IconThemeData(color: brandColor),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: blackColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      dividerColor: divider,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: brandColor,
        unselectedItemColor: textSecondary,
      ),
    );
  }

  // Helper methods to get theme-aware colors based on context
  static Color getCardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardBg : cardBgLight;
  static Color getSurfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : surfaceLight;
  static Color getSegmentedBgColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : segmentedBgLight;
  static Color getBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;
  static Color getInputBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? inputBorderDark : inputBorderLight;
  static Color getTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimary : textPrimaryLight;
  static Color getSecondaryTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : textSecondaryLight;
  static Color getDividerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? divider : dividerLight;
  static Color getBrandTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? brandColor : brandTextLight;
}
