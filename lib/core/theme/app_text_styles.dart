import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headline XL - 40px Bold
  static TextStyle headlineXl = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
  );

  // Headline LG - 32px Bold
  static TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  // Headline LG Mobile - 28px Bold
  static TextStyle headlineLgMobile = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.28,
    color: AppColors.onSurface,
  );

  // Headline MD - 24px SemiBold
  static TextStyle headlineMd = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // Body LG - 18px Regular
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  // Body MD - 16px Regular
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  // Label MD - 14px SemiBold
  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.7,
    color: AppColors.onSurface,
  );

  // Label SM - 12px Medium
  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );

  // Variantes colorees
  static TextStyle headlineLgWhite = headlineLg.copyWith(color: AppColors.white);
  static TextStyle headlineMdWhite = headlineMd.copyWith(color: AppColors.white);
  static TextStyle bodyMdWhite = bodyMd.copyWith(color: AppColors.white);
  static TextStyle bodyMdMuted = bodyMd.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle labelMdPrimary = labelMd.copyWith(color: AppColors.primary);
}
