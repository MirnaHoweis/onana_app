import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        height: 1.2,
      );

  static TextStyle get headingLarge => GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        height: 1.25,
      );

  static TextStyle get headingMedium => GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.deepCharcoal,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.deepCharcoal,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedBlueGray,
        letterSpacing: 0.4,
      );
}
