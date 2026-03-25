import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.softGold,
          onPrimary: AppColors.deepCharcoal,
          secondary: AppColors.softGoldLight,
          onSecondary: AppColors.deepCharcoal,
          surface: AppColors.warmWhite,
          onSurface: AppColors.deepCharcoal,
          error: AppColors.errorRed,
          onError: AppColors.cardSurface,
        ),
        scaffoldBackgroundColor: AppColors.warmWhite,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: AppTypography.displayLarge,
          displayMedium: AppTypography.displayMedium,
          headlineLarge: AppTypography.headingLarge,
          headlineMedium: AppTypography.headingMedium,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          labelLarge: AppTypography.labelLarge,
          labelSmall: AppTypography.labelSmall,
        ),
        cardTheme: CardTheme(
          color: AppColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.softGold,
            foregroundColor: AppColors.deepCharcoal,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: AppTypography.labelLarge,
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.sandBeige,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.softGold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.mutedBlueGray,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.mutedBlueGray,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.warmWhite,
          foregroundColor: AppColors.deepCharcoal,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.headingMedium,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardSurface,
          selectedItemColor: AppColors.softGold,
          unselectedItemColor: AppColors.mutedBlueGray,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.sandBeige,
          labelStyle: AppTypography.labelSmall,
          shape: const StadiumBorder(),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 0,
        ),
      );
}
