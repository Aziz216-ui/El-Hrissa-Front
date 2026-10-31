import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/welcome/welcome_characters.dart';

/// Lui et elle, dans une arche, pour les écrans vides : les mêmes personnages que sur l'accueil, au repos.
class CoupleArt extends StatelessWidget {
  const CoupleArt({super.key});

  static const _still = AlwaysStoppedAnimation<double>(0.3);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: Container(
          width: 200,
          height: 150,
          color: AppColors.pastelPink,
          child: Stack(
            children: [
              Positioned(
                left: 6,
                bottom: -22,
                child: Transform.rotate(
                  angle: 0.07,
                  child: CustomPaint(size: const Size(100, 125), painter: PersonPainter(_still, man: true)),
                ),
              ),
              Positioned(
                right: 6,
                bottom: -22,
                child: Transform.rotate(
                  angle: -0.07,
                  child: CustomPaint(size: const Size(100, 125), painter: PersonPainter(_still, man: false)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
