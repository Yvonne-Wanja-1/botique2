import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Queens' Touch Gold + Purple palette.
///
/// Dark purple surfaces, bold gold accents, warm white text.
class QueensTouchColors {
  QueensTouchColors._();

  static const Color plum = Color(0xFFD4AF37);
  static const Color plumDark = Color(0xFF0E0A1A);
  static const Color plumLight = Color(0xFF3D1F5C);
  static const Color blush = Color(0xFF1A0F2E);
  static const Color blushLight = Color(0xFF130B22);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFF8E7);
  static const Color cream = Color(0xFF110D1F);
  static const Color textDark = Color(0xFFFFF8E7);
  static const Color textMuted = Color(0xFF9B8DB5);
  static const Color success = Color(0xFF71816C);
  static const Color danger = Color(0xFFA6535C);
  static const Color warning = Color(0xFFD4AF37);
  static const Color surfaceLight = Color(0xFF1E1435);
  static const Color surfaceBorder = Color(0xFF2E1F4A);
  static const Color onGold = Color(0xFF1A0F2E);

  // Semantic aliases.
  static const Color deepPurple = Color(0xFF110D1F);
  static const Color royalPurple = Color(0xFF2A1547);
  static const Color lavender = Color(0xFF9B8DB5);
}

class QueensTouchTheme {
  QueensTouchTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: QueensTouchColors.gold,
        brightness: Brightness.dark,
        primary: QueensTouchColors.gold,
        secondary: QueensTouchColors.royalPurple,
        surface: QueensTouchColors.surfaceLight,
      ),
      scaffoldBackgroundColor: QueensTouchColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: QueensTouchColors.cream,
        foregroundColor: QueensTouchColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QueensTouchColors.gold,
          foregroundColor: QueensTouchColors.onGold,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QueensTouchColors.gold,
          side: const BorderSide(color: QueensTouchColors.gold),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QueensTouchColors.gold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QueensTouchColors.surfaceLight,
        hintStyle: const TextStyle(color: QueensTouchColors.textMuted),
        labelStyle: const TextStyle(color: QueensTouchColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QueensTouchColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QueensTouchColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QueensTouchColors.gold, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QueensTouchColors.blushLight,
        selectedColor: QueensTouchColors.gold,
        labelStyle: const TextStyle(color: QueensTouchColors.textDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: QueensTouchColors.surfaceBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QueensTouchColors.surfaceBorder,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: QueensTouchColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: QueensTouchColors.surfaceBorder),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: QueensTouchColors.surfaceLight,
        contentTextStyle: TextStyle(color: QueensTouchColors.textDark),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Editorial serif for brand moments (wordmark, hero, section titles).
  static TextStyle brandSerif({
    double fontSize = 24,
    FontWeight weight = FontWeight.w600,
    Color color = QueensTouchColors.textDark,
    double height = 1.15,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}