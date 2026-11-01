import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'harissa_shell.dart';

/// Sur le site, un grand écran ne doit pas étirer l'app : on la présente comme un téléphone, au centre,
/// devant le mur étoilé. Sur un téléphone ou dans l'APK, rien ne change.
class WebFrame extends StatelessWidget {
  final Widget child;
  const WebFrame({super.key, required this.child});

  static const double maxWidth = 480;
  static const double _breakpoint = 720;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _breakpoint) return child;
        // Une marge verticale seulement si l'écran est assez haut
        final margin = constraints.maxHeight > 760 ? 20.0 : 0.0;
        final height = constraints.maxHeight - margin * 2;
        return ColoredBox(
          color: AppColors.primary,
          child: Stack(
            children: [
              const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: TileWallPainter()))),
              Center(
                child: Container(
                  width: maxWidth,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(margin > 0 ? 28 : 0),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 16))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaQuery(
                    // L'app croit avoir un écran de téléphone : feuilles et mises en page restent dans le cadre
                    data: MediaQuery.of(context).copyWith(size: Size(maxWidth, height)),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
