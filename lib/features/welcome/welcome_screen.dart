import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../legal/legal_screen.dart';

/// Écran d'accueil avant la connexion.
///
/// L'idée : l'app s'appelle Elahrisa, comme la harissa, et la boîte de harissa est l'objet que
/// chaque table tunisienne connaît. L'écran est son étiquette : un fond rouge imprimé de
/// carreaux étoilés (khatem), « أهلا بيك » peint en grand comme une enseigne de souk, un piment
/// blanc en réserve, des fleurs de jasmin, et une étiquette blanche à bord festonné qui ne porte
/// qu'une phrase, en arabe tunisien, et les deux boutons.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _intro.forward();
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: _TileWallPainter()))),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const SafeArea(bottom: false, child: _TopBar()),
                  const Expanded(child: _Hero()),
                  _Label(intro: _intro),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------ Haut

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          Semantics(
            label: 'Elahrisa',
            excludeSemantics: true,
            child: Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.white, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(width: 8),
          const ExcludeSemantics(
            child: CustomPaint(size: Size(18, 24), painter: _ChiliPainter(body: AppColors.white, shade: AppColors.white, cap: AppColors.saffron)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------ Décor

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final chiliHeight = math.min(box.maxHeight * 0.6, 190.0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // L'enseigne : « Bienvenue » peint en grand, un peu de travers comme à la main
            Align(
              alignment: const Alignment(0, -0.3),
              child: Transform.rotate(
                angle: -0.05,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: 'Ahla bik, bienvenue en arabe tunisien',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'أهلا بيك',
                              style: GoogleFonts.lalezar(fontSize: 112, color: AppColors.white, height: 1.15),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const CustomPaint(size: Size(250, 18), painter: _BrushStrokePainter()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Piment en réserve, à droite
            Positioned(
              right: 20,
              bottom: 2,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: 0.2,
                  child: CustomPaint(
                    size: Size(chiliHeight * 0.78, chiliHeight),
                    painter: const _ChiliPainter(body: AppColors.white, shade: Color(0xFFF2D4D1), cap: AppColors.saffron),
                  ),
                ),
              ),
            ),
            // Jasmin, à gauche
            const Positioned(
              left: 12,
              bottom: 4,
              child: ExcludeSemantics(
                child: CustomPaint(size: Size(150, 96), painter: _JasminePainter()),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Carreaux étoilés à huit branches (khatem), pleins, ton sur ton.
class _TileWallPainter extends CustomPainter {
  const _TileWallPainter();

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

/// Coup de pinceau safran sous l'enseigne.
class _BrushStrokePainter extends CustomPainter {
  const _BrushStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.02, h * 0.55)
      ..cubicTo(w * 0.2, h * 0.05, w * 0.34, h * 0.95, w * 0.52, h * 0.45)
      ..cubicTo(w * 0.66, h * 0.05, w * 0.82, h * 0.85, w * 0.98, h * 0.35);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7
        ..color = AppColors.saffron,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Un piment, courbe et pointe vers le bas.
class _ChiliPainter extends CustomPainter {
  final Color body;
  final Color shade;
  final Color cap;
  const _ChiliPainter({required this.body, required this.shade, required this.cap});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.17)
      ..cubicTo(w * 0.62, h * 0.1, w * 0.8, h * 0.12, w * 0.85, h * 0.27)
      ..cubicTo(w * 0.94, h * 0.56, w * 0.62, h * 0.86, w * 0.2, h * 0.98)
      ..cubicTo(w * 0.52, h * 0.72, w * 0.4, h * 0.55, w * 0.4, h * 0.34)
      ..cubicTo(w * 0.4, h * 0.25, w * 0.44, h * 0.2, w * 0.5, h * 0.17)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = body);

    // Reflet : une zone pleine, coupée par la forme du piment
    if (shade != body) {
      canvas.save();
      canvas.clipPath(bodyPath);
      canvas.drawCircle(Offset(w * 0.22, h * 0.5), w * 0.3, Paint()..color = shade);
      canvas.restore();
    }

    // Tige et chapeau
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, h * 0.13)
        ..quadraticBezierTo(w * 0.64, h * 0.04, w * 0.8, h * 0.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.09
        ..color = cap,
    );
    canvas.save();
    canvas.translate(w * 0.64, h * 0.15);
    canvas.rotate(-0.12);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.5, height: h * 0.085), Paint()..color = cap);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Une branche de jasmin : trois fleurs blanches à cœur safran et quelques feuilles.
class _JasminePainter extends CustomPainter {
  const _JasminePainter();

  static const _leaf = Color(0xFF2F7D52);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.04, h * 0.98)
        ..cubicTo(w * 0.3, h * 0.78, w * 0.5, h * 0.55, w * 0.9, h * 0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = _leaf,
    );
    final leaf = Paint()..color = _leaf;
    for (final l in const [
      [0.2, 0.86, -0.9],
      [0.42, 0.7, 0.5],
      [0.62, 0.45, -0.8],
      [0.78, 0.32, 0.6],
    ]) {
      canvas.save();
      canvas.translate(w * l[0], h * l[1]);
      canvas.rotate(l[2]);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.04, 0), width: w * 0.15, height: w * 0.06), leaf);
      canvas.restore();
    }
    _flower(canvas, Offset(w * 0.9, h * 0.2), w * 0.095);
    _flower(canvas, Offset(w * 0.56, h * 0.5), w * 0.085);
    _flower(canvas, Offset(w * 0.3, h * 0.74), w * 0.075);
  }

  void _flower(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / 5 - math.pi / 2);
      canvas.drawOval(Rect.fromCenter(center: Offset(r * 0.55, 0), width: r * 1.15, height: r * 0.7), Paint()..color = AppColors.white);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.22, Paint()..color = AppColors.saffron);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------------ Étiquette

/// Bord supérieur en festons, comme le papier d'une étiquette ou une dentelle de zellige.
class _ScallopClipper extends CustomClipper<Path> {
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

class _Label extends StatelessWidget {
  final Animation<double> intro;
  const _Label({required this.intro});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(intro.value);
        return Transform.translate(offset: Offset(0, 36 * (1 - t)), child: child);
      },
      child: ClipPath(
        clipper: _ScallopClipper(),
        child: Container(
          width: double.infinity,
          color: AppColors.surfaceWhite,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Une seule phrase, en arabe tunisien : « rencontres et sorties »
                  Semantics(
                    header: true,
                    label: 'Rencontres et sorties, en arabe tunisien',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'تعارف وخرجات',
                          style: GoogleFonts.arefRuqaa(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Créer un compte'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidiTint,
                      foregroundColor: AppColors.sidi,
                      elevation: 0,
                    ),
                    child: const Text('Se connecter'),
                  ),
                  const SizedBox(height: 2),
                  const Center(child: LegalLinks.short()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
