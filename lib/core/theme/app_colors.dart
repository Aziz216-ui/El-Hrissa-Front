import 'package:flutter/material.dart';

/// Palette Elahrisa.
/// Rouge harissa = les personnes (matchs, likes). Bleu Sidi Bou = les sorties (événements, lieux).
class AppColors {
  // Harissa - Couleur principale
  static const Color primary = Color(0xFFB3141D);
  static const Color primaryDark = Color(0xFF8A0D15);
  static const Color primaryContainer = Color(0xFFD32F2F);

  // Bleu Sidi Bou - événements et lieux
  static const Color sidi = Color(0xFF1D4E9E);
  static const Color sidiTint = Color(0xFFE3ECFA);

  // Safran - petits signaux (badges, nouveautés)
  static const Color saffron = Color(0xFFE9A23B);

  // Secondaire (conservé pour le thème Material)
  static const Color secondary = Color(0xFF1D4E9E);
  static const Color secondaryContainer = Color(0xFFE3ECFA);

  // Backgrounds - chaux (blanc froid des murs de Sidi Bou Saïd)
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFF4F6F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFEBEEF3);
  static const Color surfaceContainer = Color(0xFFE1E6ED);

  // Texte
  static const Color onSurface = Color(0xFF181B25);
  static const Color onSurfaceVariant = Color(0xFF4A5468);
  static const Color outline = Color(0xFF6B7588);
  static const Color outlineVariant = Color(0xFFD5DBE5);

  // Teinte rose (chips, bandeaux d'info)
  static const Color pastelPink = Color(0xFFFBE4E2);
  static const Color pastelPinkDim = Color(0xFFF3B7B3);

  // Utilitaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF181B25);
  static const Color error = Color(0xFFBA1A1A);
  static const Color transparent = Colors.transparent;

  // Gradient overlay pour les cartes photo
  static const LinearGradient photoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xD9101420)],
    stops: [0.45, 1.0],
  );

  // Gradient bouton rouge
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB3141D)],
  );
}

/// Rayons par niveau de hiérarchie (évite un seul rayon partout).
class AppRadius {
  static const double control = 14; // boutons, champs
  static const double card = 20; // cartes de liste
  static const double sheet = 28; // feuilles modales, grande carte photo
}
