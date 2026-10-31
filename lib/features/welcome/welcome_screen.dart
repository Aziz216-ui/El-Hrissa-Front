import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../legal/legal_screen.dart';

/// Écran d'accueil avant la connexion.
/// Un mur harissa à motif de zellige (étoiles khatem), et au centre la porte bleue de Sidi Bou Saïd,
/// cloutée de laiton, qui s'entrouvre une seule fois à l'arrivée. Un jasmin, le porte-bonheur
/// que l'on offre en Tunisie, orne l'arche.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _door = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _door.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _door.forward();
      });
    }
  }

  @override
  void dispose() {
    _door.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(child: _Hero(door: _door)),
              const _Sheet(),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------ Décor

class _Hero extends StatelessWidget {
  final Animation<double> door;
  const _Hero({required this.door});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Illustration : une porte bleue tunisienne aux clous dorés, ornée de jasmin',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.35),
              radius: 1.05,
              colors: [AppColors.primaryContainer, AppColors.primary, AppColors.primaryDark],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ZelligePainter())),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Elahrisa 🌶️',
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.white, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final doorWidth = math.min(box.maxWidth * 0.6, (box.maxHeight - 72) / 1.5);
                    if (doorWidth < 60) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: Size(doorWidth, doorWidth * 1.5),
                        painter: _DoorPainter(door),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Étoiles à huit branches (khatem) de la mosaïque, ton sur ton.
class _ZelligePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 58.0;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.white.withAlpha(30);
    final dot = Paint()..color = AppColors.white.withAlpha(22);
    const side = cell * 0.6;
    for (var row = 0; row * cell < size.height + cell; row++) {
      for (var col = 0; col * cell < size.width + cell; col++) {
        final c = Offset(col * cell + (row.isOdd ? cell / 2 : 0), row * cell * 0.86);
        for (final angle in const [0.0, math.pi / 4]) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(angle);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: side, height: side), line);
          canvas.restore();
        }
        canvas.drawCircle(c, 2.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Porte en arc outrepassé : cadre blanc chaux, deux vantaux bleu Sidi Bou clous laiton, jasmin.
class _DoorPainter extends CustomPainter {
  final Animation<double> progress;
  _DoorPainter(this.progress) : super(repaint: progress);

  static const _brass = AppColors.saffron;
  static const _leafGreen = Color(0xFF2F7D52);

  /// Arc outrepassé : un peu plus qu'un demi-cercle, resserré au pied.
  Path _arch(double width, double height, double inset) {
    final w = width - 2 * inset;
    final r = w / 2 * 1.07;
    final a = math.acos((w / 2) / r);
    final cx = width / 2;
    final cy = inset + r;
    return Path()
      ..moveTo(cx - w / 2, height)
      ..lineTo(cx - w / 2, cy + r * math.sin(a))
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi - a, math.pi + 2 * a, false)
      ..lineTo(cx + w / 2, height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOutCubic.transform(progress.value.clamp(0.0, 1.0));
    final w = size.width;
    final h = size.height;
    final frame = w * 0.07;

    final outer = _arch(w, h, 0);
    final inner = _arch(w, h, frame);

    canvas.drawShadow(outer, const Color(0xFF3A0508), 14, true);
    canvas.drawPath(outer, Paint()..color = AppColors.surfaceWhite);

    // Lumière chaude derrière les vantaux
    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF1CC), AppColors.saffron],
        ).createShader(Offset.zero & size),
    );

    // Vantaux
    canvas.save();
    canvas.clipPath(inner);
    final innerWidth = w - 2 * frame;
    final leafWidth = innerWidth / 2;
    final scaleX = 1 - 0.46 * t;
    for (final side in const [-1, 1]) {
      canvas.save();
      canvas.translate(w / 2 + side * innerWidth / 2, 0);
      canvas.scale(-side * scaleX, 1);
      _paintLeaf(canvas, leafWidth, h, t);
      canvas.restore();
    }
    canvas.restore();

    // Filet laiton le long de l'arche
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * 0.012)
        ..color = _brass,
    );

    _paintJasmine(canvas, size);
  }

  /// Un vantail dessiné de la charnière (x = 0) vers le centre (x > 0).
  void _paintLeaf(Canvas canvas, double lw, double h, double t) {
    final rect = Rect.fromLTWH(0, 0, lw, h);
    canvas.drawRect(rect, Paint()..color = AppColors.sidi);

    // Planches
    final plank = Paint()
      ..color = const Color(0xFF123677).withAlpha(120)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(lw * i / 3, 0), Offset(lw * i / 3, h), plank);
    }

    // Clous en quinconce
    final step = lw / 4.2;
    final stud = Paint()..color = _brass;
    final glint = Paint()..color = const Color(0xFFFFE6A8);
    final r = step * 0.2;
    var row = 0;
    for (var y = step * 0.9; y < h; y += step * 0.82, row++) {
      for (var x = step * 0.5 + (row.isOdd ? step / 2 : 0); x < lw - step * 0.2; x += step) {
        canvas.drawCircle(Offset(x, y), r, stud);
        canvas.drawCircle(Offset(x - r * 0.3, y - r * 0.3), r * 0.38, glint);
      }
    }

    // Anneau de la porte, qui s'efface quand elle s'ouvre
    final ringCenter = Offset(lw - lw * 0.22, h * 0.6);
    final ringAlpha = ((1 - t) * 255).round();
    if (ringAlpha > 0) {
      canvas.drawCircle(
        ringCenter,
        lw * 0.17,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 0.045
          ..color = _brass.withAlpha(ringAlpha),
      );
    }

    // Ombre côté charnière, plus marquée quand le vantail s'ouvre
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFF0A1F44).withAlpha((70 + 90 * t).round()), Colors.transparent],
          stops: const [0.0, 0.7],
        ).createShader(rect),
    );
  }

  void _paintJasmine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Liane qui retombe à droite de l'arche
    final vine = Path()
      ..moveTo(w * 0.93, h * 0.2)
      ..cubicTo(w * 1.04, h * 0.3, w * 0.98, h * 0.42, w * 1.03, h * 0.55);
    canvas.drawPath(
      vine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round
        ..color = _leafGreen,
    );
    final leaf = Paint()..color = _leafGreen;
    for (final p in [Offset(w * 1.0, h * 0.32), Offset(w * 0.99, h * 0.44), Offset(w * 1.03, h * 0.5)]) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(-0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.07, height: w * 0.032), leaf);
      canvas.restore();
    }

    final r = w * 0.058;
    for (final f in [
      Offset(w * 0.5, w * 0.015),
      Offset(w * 0.5 - w * 0.17, w * 0.085),
      Offset(w * 0.5 + w * 0.17, w * 0.085),
      Offset(w * 0.96, h * 0.24),
      Offset(w * 1.01, h * 0.38),
      Offset(w * 1.04, h * 0.54),
    ]) {
      _flower(canvas, f, r);
    }
  }

  /// Fleur de jasmin : cinq pétales blancs, cœur safran.
  void _flower(Canvas canvas, Offset c, double r) {
    final petal = Paint()..color = AppColors.white;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFE5D9C3);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / 5 - math.pi / 2);
      final rect = Rect.fromCenter(center: Offset(r * 0.55, 0), width: r * 1.1, height: r * 0.62);
      canvas.drawOval(rect, petal);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.2, Paint()..color = _brass);
  }

  @override
  bool shouldRepaint(covariant _DoorPainter oldDelegate) => false;
}

// ------------------------------------------------------------------------ Feuille

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 14,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Ahla bik', style: AppTextStyles.headlineXl.copyWith(color: AppColors.primary)),
                  ),
                  // « Bienvenue » en arabe : lu de droite à gauche, sans dépendre d'une police système
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'أهلا بيك',
                        semanticsLabel: 'Bienvenue, en arabe tunisien',
                        style: GoogleFonts.reemKufi(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.sidi),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rencontrez des gens près de chez vous et sortez ensemble, de Tunis à Djerba.',
                style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Créer un compte'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text("J'ai déjà un compte"),
              ),
              const SizedBox(height: 6),
              const Center(child: LegalLinks()),
            ],
          ),
        ),
      ),
    );
  }
}
