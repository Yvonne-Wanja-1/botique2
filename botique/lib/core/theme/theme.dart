import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QueensTouchColors {
  QueensTouchColors._();

  static const Color plum = Color(0xFF6D2E4F);
  static const Color plumDark = Color(0xFF4A1E36);
  static const Color plumLight = Color(0xFF8E4A6B);
  static const Color blush = Color(0xFFE8C4CE);
  static const Color blushLight = Color(0xFFF8EDF0);
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldLight = Color(0xFFE8D5A8);
  static const Color cream = Color(0xFFFDF8F5);
  static const Color textDark = Color(0xFF2B1E26);
  static const Color textMuted = Color(0xFF7A6B72);
  static const Color success = Color(0xFF2E7D55);
  static const Color danger = Color(0xFFC0392B);
  static const Color warning = Color(0xFFB9770E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
}

class QueensTouchTheme {
  QueensTouchTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: QueensTouchColors.plum,
        primary: QueensTouchColors.plum,
        secondary: QueensTouchColors.gold,
        surface: QueensTouchColors.cream,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QueensTouchColors.plum,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QueensTouchColors.plum,
          side: const BorderSide(color: QueensTouchColors.plum),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4D5DA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4D5DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QueensTouchColors.plum, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QueensTouchColors.blushLight,
        selectedColor: QueensTouchColors.plum,
        labelStyle: const TextStyle(color: QueensTouchColors.textDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEDFE4),
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEDFE4)),
        ),
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
