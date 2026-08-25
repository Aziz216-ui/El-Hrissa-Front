import 'package:flutter/material.dart';

class AppColors {
  // Harissa Red - Couleur principale
  static const Color primary = Color(0xFFAF101A);
  static const Color primaryDark = Color(0xFF930010);
  static const Color primaryContainer = Color(0xFFD32F2F);

  // Coral - Couleur secondaire
  static const Color secondary = Color(0xFFAC3509);
  static const Color secondaryContainer = Color(0xFFFE6F42);

  // Backgrounds
  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFFCF9F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDED);

  // Texte
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF5B403D);
  static const Color outline = Color(0xFF8F6F6C);
  static const Color outlineVariant = Color(0xFFE4BEBA);

  // Pastel Pink (chips, tags)
  static const Color pastelPink = Color(0xFFFFDAD6);
  static const Color pastelPinkDim = Color(0xFFFFB3AC);

  // Utilitaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1B1C1C);
  static const Color error = Color(0xFFBA1A1A);
  static const Color transparent = Colors.transparent;

  // Gradient overlay pour les cartes photo
  static const LinearGradient photoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
    stops: [0.4, 1.0],
  );

  // Gradient bouton rouge
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFAF101A)],
  );
}
