import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Queens' Touch premium dark palette.
///
/// The constant names are kept for source compatibility with the rest of the
/// app while the values implement the refined quiet-luxury look:
/// warm black surfaces, deep espresso accents, warm ivory text, muted gold accents.
class QueensTouchColors {
  QueensTouchColors._();

  static const Color plum = Color(0xFF2B211E);
  static const Color plumDark = Color(0xFF0F0D0B);
  static const Color plumLight = Color(0xFF3D3228);
  static const Color blush = Color(0xFF24201F);
  static const Color blushLight = Color(0xFF1F1B18);
  static const Color gold = Color(0xFFC6A15B);
  static const Color goldLight = Color(0xFFFAF7F2);
  static const Color cream = Color(0xFF1A1611);
  static const Color textDark = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF766C67);
  static const Color success = Color(0xFF71816C);
  static const Color danger = Color(0xFFA6535C);
  static const Color warning = Color(0xFFC6A15B);
  static const Color surfaceLight = Color(0xFF2B211E);
  static const Color surfaceBorder = Color(0xFF3D3228);
  static const Color onGold = Color(0xFFFAF7F2);

  // Semantic aliases for the Quiet Luxury spec.
  static const Color deepEspresso = Color(0xFF2B211E);
  static const Color warmIvory = Color(0xFFFAF7F2);
  static const Color dustyRose = Color(0xFFB76E79);
  static const Color softTaupe = Color(0xFFE8DED7);
  static const Color richCharcoal = Color(0xFF24201F);
}

class QueensTouchTheme {
  QueensTouchTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: QueensTouchColors.plum,
        brightness: Brightness.dark,
        primary: QueensTouchColors.plum,
        secondary: QueensTouchColors.gold,
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
          backgroundColor: QueensTouchColors.plum,
          foregroundColor: QueensTouchColors.onGold,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QueensTouchColors.goldLight,
          side: const BorderSide(color: QueensTouchColors.gold),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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