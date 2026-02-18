import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide color palette inspired by water/duck theme
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF36708B);
  static const Color primaryLight = Color(0xFF5C9CB5);
  static const Color primaryDark = Color(0xFF1B4D63);

  // Accent / secondary
  static const Color accent = Color(0xFF6CCCD1);
  static const Color accentLight = Color(0xFF9BE8EC);
  static const Color accentDark = Color(0xFF3AAFB6);

  // Background gradients
  static const Color gradientTop = Color(0xFFE8F4FC);
  static const Color gradientBottom = Color(0xFFB8E4E8);

  // Surface & background
  static const Color surface = Color(0xFFF5FAFF);
  static const Color surfaceLight = Color(0xFFF0F5FA);
  static const Color surfaceVariant = Color(0xFFE8F4FD);
  static const Color background = Color(0xFFF0F8FF);
  static const Color card = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A2B3C);
  static const Color textSecondary = Color(0xFF5A6B7C);
  static const Color textHint = Color(0xFF8A9BAC);

  // Water / Wave
  static const Color water = Color(0xFF4FC3F7);
  static const Color waterDark = Color(0xFF0288D1);
  static const Color waterLight = Color(0xFFB3E5FC);

  // Streaks
  static const Color streakBronze = Color(0xFFCD7F32);
  static const Color streakSilver = Color(0xFFC0C0C0);
  static const Color streakGold = Color(0xFFFFD700);
  static const Color streakPlatinum = Color(0xFF36708B);
  static const Color streakDefault = Color(0xFF90CAF9);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Challenge colors
  static const List<Color> challengeColors = [
    Color(0xFF42A5F5), // Nothing But Water
    Color(0xFF66BB6A), // Tea Time
    Color(0xFF8D6E63), // Caffeine Cut
    Color(0xFFEF5350), // Sugar-Free Sips
    Color(0xFFFFA726), // Dairy-Free Refresh
    Color(0xFFAB47BC), // Vitamin Vitality
  ];

  // Duck collection tier colors
  static const Color duckCommon = Color(0xFF90CAF9);
  static const Color duckRare = Color(0xFF66BB6A);
  static const Color duckEpic = Color(0xFFAB47BC);
  static const Color duckLegendary = Color(0xFFFFD700);

  // Misc
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFE0E8F0);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3F2FD), Color(0xFFB3E5FC)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x264FC3F7), Color(0x994FC3F7)],
  );
}

/// App-wide text styles
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.cherryBombOne(
        fontSize: 48,
        color: AppColors.primary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get displayMedium => GoogleFonts.cherryBombOne(
        fontSize: 36,
        color: AppColors.primary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get displaySmall => GoogleFonts.cherryBombOne(
        fontSize: 28,
        color: AppColors.primary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get waterAmount => GoogleFonts.cherryBombOne(
        fontSize: 48,
        color: AppColors.primary,
      );

  static TextStyle get streakCount => GoogleFonts.cherryBombOne(
        fontSize: 64,
        color: AppColors.primary,
      );
}

/// App Theme Data
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.primary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
