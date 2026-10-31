import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Lui et elle, dessinés comme des autocollants au contour blanc.
/// Ils respirent, clignent des yeux, et le gland de la chéchia balance.
/// Lui porte la chéchia et un bouquet de jasmin derrière l'oreille ; elle, un jasmin dans les cheveux.
class PersonPainter extends CustomPainter {
  final Animation<double> t;
  final bool man;
  PersonPainter(this.t, {required this.man}) : super(repaint: t);

  static const _ink = Color(0xFF2A1A14);
  static const _chechia = Color(0xFFA3121B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final phase = t.value;
    final wave = math.sin(phase * 2 * math.pi + (man ? 0 : 1.4));
    final b = wave * 2.4; // la respiration
    final tilt = wave * 0.035;
    final blink = man ? (phase > 0.80 && phase < 0.85) : (phase > 0.30 && phase < 0.35);

    final top = man ? AppColors.sidi : AppColors.saffron;
    final body = Path()
      ..moveTo(6, 160)
      ..cubicTo(6, 118, 28, 104 + b * 0.4, 60, 104 + b * 0.4)
      ..cubicTo(92, 104 + b * 0.4, 114, 118, 114, 160)
      ..close();

    // 1. contour blanc, 2. couleurs
    for (final outline in [true, false]) {
      _shape(canvas, body, top, outline);
      canvas.save();
      canvas.translate(60, 98);
      canvas.rotate(tilt);
      canvas.translate(-60, -98);
      _head(canvas, b, blink, outline);
      canvas.restore();
    }
  }

  void _shape(Canvas canvas, Path path, Color color, bool outline) {
    if (outline) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, Paint()..color = AppColors.white);
    } else {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _head(Canvas canvas, double b, bool blink, bool outline) {
    final skin = man ? const Color(0xFFD9A07A) : const Color(0xFFEBBF9A);
    final head = Path()..addOval(Rect.fromCenter(center: Offset(60, 62 + b), width: 52, height: 58));
    final cap = Path()
      ..moveTo(33, 51 + b)
      ..cubicTo(32, 16 + b, 88, 16 + b, 87, 51 + b)
      ..close();

    if (man) {
      final ears = Path()
        ..addOval(Rect.fromCenter(center: Offset(34, 63 + b), width: 11, height: 13))
        ..addOval(Rect.fromCenter(center: Offset(86, 63 + b), width: 11, height: 13));
      _shape(canvas, ears, skin, outline);
      _shape(canvas, head, skin, outline);
      _shape(canvas, cap, _chechia, outline);
    } else {
      final hairBack = Path()
        ..moveTo(24, 70 + b)
        ..cubicTo(14, 14 + b, 106, 14 + b, 96, 70 + b)
        ..cubicTo(104, 100 + b, 100, 128 + b, 96, 140 + b)
        ..lineTo(24, 140 + b)
        ..cubicTo(20, 128 + b, 16, 100 + b, 24, 70 + b)
        ..close();
      _shape(canvas, hairBack, const Color(0xFF2B1A14), outline);
      _shape(canvas, head, skin, outline);
    }
    if (outline) return;

    // Cou : une pièce de peau sous le menton
    canvas.drawRect(Rect.fromLTWH(51, 84 + b * 0.5, 18, 22), Paint()..color = skin);
    canvas.drawPath(head, Paint()..color = skin);

    // Col
    final collar = Path()
      ..moveTo(man ? 45 : 48, 104)
      ..lineTo(60, man ? 126 : 120)
      ..lineTo(man ? 75 : 72, 104)
      ..close();
    canvas.drawPath(collar, Paint()..color = man ? AppColors.white : skin);

    // Joues
    final cheek = Paint()..color = const Color(0xFFE8808A).withAlpha(95);
    canvas.drawCircle(Offset(44, 71 + b), 5.5, cheek);
    canvas.drawCircle(Offset(76, 71 + b), 5.5, cheek);

    if (man) {
      canvas.drawPath(cap, Paint()..color = _chechia);
      canvas.drawPath(
        Path()
          ..moveTo(33, 51 + b)
          ..lineTo(87, 51 + b)
          ..lineTo(86, 46 + b)
          ..lineTo(34, 46 + b)
          ..close(),
        Paint()..color = const Color(0xFF8A0F17),
      );
      // Gland qui balance
      final sway = math.sin(t.value * 2 * math.pi * 2) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(62, 17 + b)
          ..quadraticBezierTo(88, 4 + b, 90 + sway, 40 + b),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.4
          ..color = const Color(0xFF1B1B1B),
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(90 + sway, 44 + b), width: 8, height: 12), Paint()..color = const Color(0xFF1B1B1B));
      // Jasmin derrière l'oreille
      _flower(canvas, Offset(29, 60 + b), 4.6);
      _flower(canvas, Offset(26, 69 + b), 4.2);
      _flower(canvas, Offset(33, 72 + b), 3.8);
    } else {
      final fringe = Path()
        ..moveTo(33, 60 + b)
        ..cubicTo(32, 26 + b, 88, 22 + b, 88, 60 + b)
        ..cubicTo(78, 42 + b, 56, 38 + b, 42, 56 + b)
        ..close();
      canvas.drawPath(fringe, Paint()..color = const Color(0xFF2B1A14));
      canvas.drawCircle(Offset(33.5, 76 + b), 3.2, Paint()..color = AppColors.saffron);
      canvas.drawCircle(Offset(86.5, 76 + b), 3.2, Paint()..color = AppColors.saffron);
      _flower(canvas, Offset(82, 33 + b), 4.8);
      _flower(canvas, Offset(91, 41 + b), 4.2);
      _flower(canvas, Offset(74, 29 + b), 4.0);
    }

    // Yeux, sourcils, nez
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    for (final x in const [48.0, 72.0]) {
      if (blink) {
        canvas.drawLine(Offset(x - 4, 60 + b), Offset(x + 4, 60 + b), stroke..strokeWidth = 2.2);
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, 60 + b), width: 5.6, height: 7.4), Paint()..color = _ink);
        canvas.drawCircle(Offset(x + 1.2, 58.2 + b), 1.2, Paint()..color = AppColors.white);
      }
    }
    stroke.strokeWidth = man ? 3.2 : 2.2;
    final lift = man ? 0.0 : 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(41, 52 + b - lift)
        ..quadraticBezierTo(48, 47 + b - lift, 55, 51 + b - lift),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(65, 51 + b - lift)
        ..quadraticBezierTo(72, 47 + b - lift, 79, 52 + b - lift),
      stroke,
    );
    stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFB9805A);
    canvas.drawPath(
      Path()
        ..moveTo(60, 64 + b)
        ..quadraticBezierTo(64, 70 + b, 59, 71 + b),
      stroke,
    );

    if (man) {
      // Moustache, puis sourire
      canvas.drawPath(
        Path()
          ..moveTo(42, 75 + b)
          ..quadraticBezierTo(51, 66 + b, 60, 72 + b)
          ..quadraticBezierTo(69, 66 + b, 78, 75 + b)
          ..quadraticBezierTo(69, 79 + b, 60, 76 + b)
          ..quadraticBezierTo(51, 79 + b, 42, 75 + b)
          ..close(),
        Paint()..color = _ink,
      );
      stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF7A2A2A);
      canvas.drawPath(
        Path()
          ..moveTo(52, 82 + b)
          ..quadraticBezierTo(60, 89 + b, 68, 82 + b),
        stroke,
      );
    } else {
      stroke
        ..strokeWidth = 2
        ..color = _ink;
      canvas.drawLine(Offset(43, 58 + b), Offset(40, 56 + b), stroke);
      canvas.drawLine(Offset(77, 58 + b), Offset(80, 56 + b), stroke);
      canvas.drawPath(
        Path()
          ..moveTo(51, 77 + b)
          ..quadraticBezierTo(60, 89 + b, 69, 77 + b)
          ..quadraticBezierTo(60, 81 + b, 51, 77 + b)
          ..close(),
        Paint()..color = const Color(0xFFC2334A),
      );
    }
  }

  /// Fleur de jasmin : cinq pétales blancs, cœur safran.
  void _flower(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / 5 - math.pi / 2);
      canvas.drawOval(Rect.fromCenter(center: Offset(r * 0.55, 0), width: r * 1.15, height: r * 0.7), Paint()..color = AppColors.white);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.24, Paint()..color = AppColors.saffron);
  }

  @override
  bool shouldRepaint(covariant PersonPainter oldDelegate) => oldDelegate.man != man;
}

/// Quelques cœurs qui montent entre les deux personnages.
class HeartsPainter extends CustomPainter {
  final Animation<double> t;
  HeartsPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final p = (t.value * 2 + i / 3) % 1.0;
      final alpha = p < 0.15 ? p / 0.15 : (p > 0.7 ? (1 - p) / 0.3 : 1.0);
      final s = 8 + p * 10;
      final c = Offset(size.width / 2 + math.sin(p * 2 * math.pi + i) * 14, size.height * 0.86 - p * size.height * 0.38);
      final heart = Path()
        ..moveTo(c.dx, c.dy + s * 0.35)
        ..cubicTo(c.dx - s, c.dy - s * 0.2, c.dx - s * 0.55, c.dy - s * 0.95, c.dx, c.dy - s * 0.45)
        ..cubicTo(c.dx + s * 0.55, c.dy - s * 0.95, c.dx + s, c.dy - s * 0.2, c.dx, c.dy + s * 0.35);
      canvas.drawPath(heart, Paint()..color = (i.isEven ? AppColors.white : AppColors.saffron).withAlpha((alpha * 255).round()));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
