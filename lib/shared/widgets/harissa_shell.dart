import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Carreaux étoilés à huit branches (khatem), pleins, ton sur ton.
class TileWallPainter extends CustomPainter {
  const TileWallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 58.0;
    const outer = 25.0;
    const inner = outer * 0.7;
    final paint = Paint()..color = const Color(0xFF9F1019);
    var row = 0;
    for (var y = 0.0; y < size.height + spacing; y += spacing * 0.9, row++) {
      for (var x = row.isOdd ? spacing / 2 : 0.0; x < size.width + spacing; x += spacing) {
        final path = Path();
        for (var i = 0; i < 16; i++) {
          final a = i * math.pi / 8 - math.pi / 2;
          final r = i.isEven ? outer : inner;
          final p = Offset(x + r * math.cos(a), y + r * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bord supérieur en festons, comme le papier d'une étiquette ou une dentelle de zellige.
class ScallopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final bumps = math.max(6, (size.width / 30).round());
    final r = size.width / (bumps * 2);
    final path = Path()..moveTo(0, r);
    for (var i = 0; i < bumps; i++) {
      path.arcToPoint(Offset((i + 1) * 2 * r, r), radius: Radius.circular(r), clockwise: true);
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Cadre des écrans qui suivent l'accueil (connexion, inscription, mot de passe oublié) :
/// le mur rouge à carreaux étoilés avec un mot arabe peint en grand, puis l'étiquette blanche
/// à bord festonné qui porte le formulaire.
class HarissaShell extends StatelessWidget {
  /// Mot en arabe tunisien, peint en grand.
  final String arabic;

  /// Titre de l'écran, en français (lu par les lecteurs d'écran).
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const HarissaShell({
    super.key,
    required this.arabic,
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: TileWallPainter()))),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.white),
                          tooltip: 'Retour',
                          onPressed: onBack,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        label: title,
                        excludeSemantics: true,
                        child: Transform.rotate(
                          angle: -0.03,
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                arabic,
                                style: GoogleFonts.lalezar(fontSize: 60, color: AppColors.white, height: 1.15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipPath(
                      clipper: ScallopClipper(),
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surfaceWhite,
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 38, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(title, style: AppTextStyles.headlineLgMobile),
                                const SizedBox(height: 20),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message d'erreur : un aplat teinté, sans cadre, avec l'icône d'alerte.
class FormErrorBox extends StatelessWidget {
  final String message;
  const FormErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: AppTextStyles.labelSm.copyWith(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}
