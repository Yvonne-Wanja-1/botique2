import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Queens' Touch purple + gold palette.
///
/// Dominant: #BA4DFF (vibrant purple). Accent: gold (#C6A15B).
/// White is used only for text on dark surfaces — never as backgrounds.
class QueensTouchColors {
  QueensTouchColors._();

  // ── Purple range (dominant) ──────────────────────────────────────────
  static const Color plum = Color(0xFFBA4DFF);           // primary purple
  static const Color plumDark = Color(0xFF7B1FA2);       // deep purple (gradients, darker surfaces)
  static const Color plumLight = Color(0xFFD08FFF);      // lighter purple highlight
  static const Color blush = Color(0xFF3D1A5E);          // dark purple (unselected dots, muted)
  static const Color blushLight = Color(0xFF2A1040);     // very dark purple (chips, selected bg)
  static const Color surfaceLight = Color(0xFF221438);   // card / elevated surface
  static const Color surfaceBorder = Color(0xFF3D2560);  // subtle border on dark
  static const Color cream = Color(0xFF1A0A2E);          // scaffold background (deep purple-black)

  // ── Gold range (accent) ──────────────────────────────────────────────
  static const Color gold = Color(0xFFC6A15B);           // bright gold
  static const Color goldLight = Color(0xFFE8D5A8);      // champagne (labels on dark)

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFFFFFFFF);       // white — main text on dark
  static const Color textMuted = Color(0xFFB09FD0);      // muted lavender

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF7D);
  static const Color danger = Color(0xFFE05252);
  static const Color warning = Color(0xFFE0A93B);
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
        primary: QueensTouchColors.gold,
        secondary: QueensTouchColors.plum,
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
          color: QueensTouchColors.textDark,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: QueensTouchColors.textDark,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: QueensTouchColors.textDark,
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
          foregroundColor: QueensTouchColors.cream,
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