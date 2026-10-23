import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Compatibility Aliases referencing AppColors ───────────────
  static const Color background = AppColors.darkBackground;
  static const Color surface = AppColors.darkSurface;
  static const Color surfaceVariant = AppColors.darkSurfaceVariant;
  static const Color surfaceElevated = AppColors.darkSurfaceElevated;
  static  Color darkBorder = Color(0xFFFFFFFF).withValues(alpha: 0.12);
  static const Color darkGlassBorder = AppColors.darkGlassBorder;

  static const Color lightBg = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightSurfaceVariant = AppColors.lightSurfaceVariant;
  static  Color lightBorder = const Color(0xFF000000).withValues(alpha: 0.08);

  static const Color primary = AppColors.darkPrimary;
  static const Color primaryDark = AppColors.lightPrimary;
  static const Color primaryDim = Color(0xFFCCCCCC);
  static const Color primaryMuted = AppColors.darkTextSecondary;
  static const Color primaryColor = AppColors.lightPrimary;

  static const Color primaryText = AppColors.darkTextPrimary;
  static const Color secondaryText = AppColors.darkTextSecondary;
  static const Color tertiaryText = AppColors.darkTextTertiary;

  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightTextTertiary = AppColors.lightTextTertiary;

  // Semantic Colors
  static const Color incomeGreen = AppColors.semanticGreen;
  static const Color expenseRed = AppColors.semanticRed;
  static const Color warningOrange = Color(0xFF9E9E9E);

  // Glass and Border compatibility
  static const Color glassSurface = Color(0x14FFFFFF);
  static const Color glassBorder = AppColors.darkGlassBorder;

  // ── Monochrome Gradients ──────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF0A0A0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient1 = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient2 = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: Color(0xFF374151),
        surface: AppColors.lightSurface,
        error: AppColors.semanticRed,
        onPrimary: AppColors.lightOnPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 26,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.lightTextSecondary,
          fontSize: 16,
        ),
        bodySmall: GoogleFonts.dmSans(
          color: AppColors.lightTextTertiary,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'DM Sans',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:  BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side:  BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:  BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.semanticRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.semanticRed, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  // ── Dark Theme (Monochrome OLED Black) ────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: Color(0xFFCCCCCC),
        surface: AppColors.darkSurface,
        error: AppColors.semanticRed,
        onPrimary: AppColors.darkOnPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 26,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.darkTextSecondary,
          fontSize: 16,
        ),
        bodySmall: GoogleFonts.dmSans(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'DM Sans',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkGlassBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: Color.fromARGB(255, 26, 26, 26), width: 1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkGlassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.semanticRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.semanticRed, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 3,
        shape: CircleBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
