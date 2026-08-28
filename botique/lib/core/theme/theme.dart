import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Queens' Touch Magenta + Gold palette.
///
/// Dark surfaces, bold magenta + gold accents, warm white text.
class QueensTouchColors {
  QueensTouchColors._();

  static const Color plum = Color(0xFFD4AF37);
  static const Color plumDark = Color(0xFF0E0A1A);
  static const Color plumLight = Color(0xFF5C1A8A);
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
  static const Color surfaceLight = Color(0xFF7F00FF);
  static const Color surfaceBorder = Color(0xFF2E1F4A);
  static const Color onGold = Color(0xFF1A0F2E);
  static const Color magenta = Color(0xFFFF00FF);

  // Semantic aliases.
  static const Color deepPurple = Color(0xFF110D1F);
  static const Color royalPurple = Color(0xFF5C1A8A);
  static const Color lavender = Color(0xFF9B8DB5);
}

class QueensTouchTheme {
  QueensTouchTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: QueensTouchColors.gold,
        onPrimary: QueensTouchColors.onGold,
        primaryContainer: QueensTouchColors.gold,
        onPrimaryContainer: QueensTouchColors.onGold,
        secondary: QueensTouchColors.magenta,
        onSecondary: Colors.white,
        secondaryContainer: QueensTouchColors.magenta,
        onSecondaryContainer: Colors.white,
        tertiary: QueensTouchColors.magenta,
        onTertiary: Colors.white,
        tertiaryContainer: QueensTouchColors.magenta,
        onTertiaryContainer: Colors.white,
        surface: QueensTouchColors.surfaceLight,
        onSurface: QueensTouchColors.textDark,
        surfaceContainerHighest: QueensTouchColors.surfaceLight,
        surfaceContainerHigh: QueensTouchColors.surfaceLight,
        surfaceContainer: QueensTouchColors.surfaceLight,
        surfaceContainerLow: QueensTouchColors.surfaceLight,
        surfaceContainerLowest: QueensTouchColors.surfaceLight,
        surfaceDim: QueensTouchColors.plumDark,
        surfaceBright: QueensTouchColors.surfaceLight,
        outline: QueensTouchColors.surfaceBorder,
        outlineVariant: QueensTouchColors.surfaceBorder,
        error: QueensTouchColors.danger,
        onError: Colors.white,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: QueensTouchColors.textDark,
        onInverseSurface: QueensTouchColors.plumDark,
        inversePrimary: QueensTouchColors.gold,
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
        iconTheme: const IconThemeData(color: QueensTouchColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QueensTouchColors.magenta,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QueensTouchColors.magenta,
          side: const BorderSide(color: QueensTouchColors.magenta),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QueensTouchColors.magenta,
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
          borderSide: const BorderSide(color: QueensTouchColors.magenta, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QueensTouchColors.blushLight,
        selectedColor: QueensTouchColors.magenta,
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: QueensTouchColors.surfaceBorder),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QueensTouchColors.magenta;
          return QueensTouchColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return QueensTouchColors.magenta.withValues(alpha: 0.4);
          }
          return QueensTouchColors.surfaceBorder;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: QueensTouchColors.magenta,
        thumbColor: QueensTouchColors.magenta,
        inactiveTrackColor: QueensTouchColors.surfaceBorder,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: QueensTouchColors.magenta,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QueensTouchColors.plumDark,
        indicatorColor: QueensTouchColors.magenta.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: QueensTouchColors.magenta, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: QueensTouchColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: QueensTouchColors.magenta);
          }
          return const IconThemeData(color: QueensTouchColors.textMuted);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: QueensTouchColors.plumDark,
        selectedIconTheme: const IconThemeData(color: QueensTouchColors.magenta),
        unselectedIconTheme: const IconThemeData(color: QueensTouchColors.textMuted),
        selectedLabelTextStyle: const TextStyle(color: QueensTouchColors.magenta, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: QueensTouchColors.textMuted),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: QueensTouchColors.magenta,
        unselectedLabelColor: QueensTouchColors.textMuted,
        indicatorColor: QueensTouchColors.magenta,
        dividerColor: QueensTouchColors.surfaceBorder,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QueensTouchColors.magenta;
          return QueensTouchColors.textMuted;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: QueensTouchColors.surfaceBorder),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QueensTouchColors.magenta;
          return QueensTouchColors.textMuted;
        }),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: QueensTouchColors.surfaceLight,
        headerBackgroundColor: QueensTouchColors.magenta,
        headerForegroundColor: Colors.white,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QueensTouchColors.magenta;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return QueensTouchColors.textDark;
        }),
        todayBackgroundColor: WidgetStateProperty.all(QueensTouchColors.magenta.withValues(alpha: 0.3)),
        todayForegroundColor: WidgetStateProperty.all(QueensTouchColors.magenta),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QueensTouchColors.magenta;
          return null;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return QueensTouchColors.textDark;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: QueensTouchColors.surfaceLight,
        titleTextStyle: const TextStyle(color: QueensTouchColors.textDark, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: QueensTouchColors.surfaceLight,
        dragHandleColor: QueensTouchColors.surfaceBorder,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: QueensTouchColors.magenta,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: QueensTouchColors.textDark,
        iconColor: QueensTouchColors.textMuted,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: QueensTouchColors.magenta,
        textColor: Colors.white,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: QueensTouchColors.magenta,
        selectionColor: QueensTouchColors.magenta.withValues(alpha: 0.3),
        selectionHandleColor: QueensTouchColors.magenta,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: QueensTouchColors.surfaceLight,
        scrimColor: QueensTouchColors.plumDark,
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