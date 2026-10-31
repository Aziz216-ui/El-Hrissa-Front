import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'harissa_shell.dart';

/// Bord inférieur en festons (l'inverse de ScallopClipper) : la bande rouge se termine comme une dentelle.
class BottomScallopClipper extends CustomClipper<Path> {
  static const double bumpRadius = 9;

  @override
  Path getClip(Size size) {
    final bumps = (size.width / (bumpRadius * 2)).ceil();
    final r = size.width / (bumps * 2);
    final baseline = size.height - r;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, baseline);
    for (var i = 0; i < bumps; i++) {
      path.arcToPoint(Offset(size.width - (i + 1) * 2 * r, baseline), radius: Radius.circular(r), clockwise: true);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// En-tête des onglets de l'app : le mur rouge à carreaux étoilés, un mot arabe peint en grand,
/// le titre en français dessous, et les actions à droite.
class TabBand extends StatelessWidget {
  /// Mot en arabe tunisien (décoratif : le titre en français est ce que lisent les lecteurs d'écran).
  final String arabic;
  final String title;
  final List<Widget> actions;

  const TabBand({super.key, required this.arabic, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomScallopClipper(),
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        child: Stack(
          children: [
            const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: TileWallPainter()))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: title,
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.rotate(
                              angle: -0.025,
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(arabic, style: GoogleFonts.lalezar(fontSize: 46, color: AppColors.white, height: 1.1)),
                                ),
                              ),
                            ),
                            Text(title, style: AppTextStyles.labelMd.copyWith(color: AppColors.white.withValues(alpha: 0.92))),
                          ],
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action blanc pour la bande rouge, avec une vraie zone de toucher.
class BandAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const BandAction({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.white),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
