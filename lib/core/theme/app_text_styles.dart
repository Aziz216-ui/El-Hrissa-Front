import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Titres : Bricolage Grotesque (caractère). Texte : Figtree (lisible, chaleureux).
class AppTextStyles {
  static TextStyle _display({
    required double size,
    FontWeight weight = FontWeight.w700,
    double spacing = 0,
    Color color = AppColors.onSurface,
  }) =>
      GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: 1.15, color: color);

  static TextStyle _text({
    required double size,
    FontWeight weight = FontWeight.w400,
    double spacing = 0,
    double height = 1.5,
    Color color = AppColors.onSurface,
  }) =>
      GoogleFonts.figtree(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: height, color: color);

  // Headline XL - 40px
  static TextStyle headlineXl = _display(size: 40, weight: FontWeight.w800, spacing: -1.0);

  // Headline LG - 32px
  static TextStyle headlineLg = _display(size: 32, spacing: -0.6);

  // Headline LG Mobile - 28px
  static TextStyle headlineLgMobile = _display(size: 28, spacing: -0.4);

  // Headline MD - 24px
  static TextStyle headlineMd = _display(size: 24, weight: FontWeight.w600, spacing: -0.2);

  // Titre de section / carte - 20px
  static TextStyle titleMd = _display(size: 20, weight: FontWeight.w600, spacing: -0.1);

  // Body LG - 18px
  static TextStyle bodyLg = _text(size: 18);

  // Body MD - 16px
  static TextStyle bodyMd = _text(size: 16);

  // Label MD - 14px SemiBold
  static TextStyle labelMd = _text(size: 14, weight: FontWeight.w600, spacing: 0.1, height: 1.3);

  // Label SM - 12px Medium
  static TextStyle labelSm = _text(size: 12.5, weight: FontWeight.w500, height: 1.35, color: AppColors.onSurfaceVariant);

  // Variantes colorees
  static TextStyle headlineLgWhite = headlineLg.copyWith(color: AppColors.white);
  static TextStyle headlineMdWhite = headlineMd.copyWith(color: AppColors.white);
  static TextStyle bodyMdWhite = bodyMd.copyWith(color: AppColors.white);
  static TextStyle bodyMdMuted = bodyMd.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle labelMdPrimary = labelMd.copyWith(color: AppColors.primary);
}
