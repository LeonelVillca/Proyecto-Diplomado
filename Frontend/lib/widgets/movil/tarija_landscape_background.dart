import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Escena ilustrada (no fotorrealista) de los valles de Tarija al atardecer.
///
/// Ocupa toda la pantalla. Está compuesta por capas planas con profundidad:
/// cielo en degradado (dorado → naranja atardecer → vino tinto), sol con
/// halo cálido, lomadas de cerros con luz de contorno (rim light), y en el
/// primer plano las hileras de vid en perspectiva. La parte baja se funde en
/// vino tinto profundo que enlaza con la tarjeta inferior.
class TarijaLandscapeBackground extends StatelessWidget {
  const TarijaLandscapeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: SunsetValleyPainter(),
      size: Size.infinite,
    );
  }
}

class SunsetValleyPainter extends CustomPainter {
  const SunsetValleyPainter();

  // Paleta del atardecer valluno.
  static const _skyTop = Color(0xFFF2A654); // dorado caliente
  static const _skyMid = Color(0xFFC97B3D); // naranja atardecer
  static const _skyLow = Color(0xFF8E2F43); // vino incipiente
  static const _wineDeep = Color(0xFF5C1A2E); // vino profundo
  static const _wineDarker = Color(0xFF4A1424);
  static const _hillFar = Color(0xFF7A2A3E);
  static const _hillMid = Color(0xFF672038);
  static const _sunCore = Color(0xFFFFE6B0);
  static const _vineFoliage = Color(0xFF3A0E1D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    _paintSky(canvas, w, h);
    _paintSun(canvas, w, h);
    _paintBirds(canvas, w, h);
    _paintFarHills(canvas, w, h);
    _paintNearHill(canvas, w, h);
    _paintVineyard(canvas, w, h);
    _paintVignette(canvas, w, h);
  }

  // ---------------------------------------------------------------------------
  // Cielo: degradado vertical dorado → naranja → vino.
  // ---------------------------------------------------------------------------
  void _paintSky(Canvas canvas, double w, double h) {
    final rect = Offset.zero & Size(w, h);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyMid, _skyLow],
        stops: [0.0, 0.42, 0.78],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // Estelas de nube translúcidas junto al sol.
    final cloudRect = Paint()..color = Colors.white.withAlpha(26);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.18, h * 0.20),
        width: w * 0.30,
        height: h * 0.012,
      ),
      cloudRect,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.74, h * 0.26),
        width: w * 0.26,
        height: h * 0.010,
      ),
      cloudRect,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.30, h * 0.31),
        width: w * 0.22,
        height: h * 0.008,
      ),
      cloudRect,
    );
  }

  // ---------------------------------------------------------------------------
  // Sol con halo radial y rescate de luz sobre los cerros.
  // ---------------------------------------------------------------------------
  void _paintSun(Canvas canvas, double w, double h) {
    final sun = Offset(w * 0.50, h * 0.235);
    final glowRadius = w * 0.34;

    // Halo amplio y suave.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _sunCore.withAlpha(150),
          _sunCore.withAlpha(40),
          Colors.transparent,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sun, radius: glowRadius));
    canvas.drawCircle(sun, glowRadius, glow);

    // Núcleo del sol.
    final core = Paint()
      ..shader = RadialGradient(
        colors: [_sunCore, const Color(0xFFF6C06E)],
      ).createShader(Rect.fromCircle(center: sun, radius: w * 0.072));
    canvas.drawCircle(sun, w * 0.07, core);
  }

  // ---------------------------------------------------------------------------
  // Pájaros lejanos en "V".
  // ---------------------------------------------------------------------------
  void _paintBirds(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _wineDeep.withAlpha(150);

    final positions = <Offset>[
      Offset(w * 0.40, h * 0.165),
      Offset(w * 0.48, h * 0.145),
      Offset(w * 0.56, h * 0.175),
    ];

    for (final p in positions) {
      final s = w * 0.006;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - s, p.dy)
          ..quadraticBezierTo(p.dx - s * 0.45, p.dy - s * 1.1, p.dx, p.dy)
          ..quadraticBezierTo(p.dx + s * 0.45, p.dy - s * 1.1, p.dx + s, p.dy),
        paint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cerros lejanos (dos lomadas superpuestas) con contraste dorado.
  // ---------------------------------------------------------------------------
  void _paintFarHills(Canvas canvas, double w, double h) {
    // Lomada más lejana.
    final paintFar = Paint()..color = _hillFar;
    final pathFar = Path()..moveTo(0, h);
    pathFar.lineTo(0, h * 0.455);
    pathFar.quadraticBezierTo(w * 0.16, h * 0.415, w * 0.34, h * 0.46);
    pathFar.quadraticBezierTo(w * 0.56, h * 0.495, w * 0.74, h * 0.455);
    pathFar.quadraticBezierTo(w * 0.90, h * 0.425, w, h * 0.465);
    pathFar.lineTo(w, h);
    pathFar.close();
    canvas.drawPath(pathFar, paintFar);

    // Lomada intermedia.
    final paintMid = Paint()..color = _hillMid;
    final pathMid = Path()..moveTo(0, h);
    pathMid.lineTo(0, h * 0.505);
    pathMid.quadraticBezierTo(w * 0.20, h * 0.455, w * 0.44, h * 0.505);
    pathMid.quadraticBezierTo(w * 0.63, h * 0.54, w * 0.80, h * 0.495);
    pathMid.quadraticBezierTo(w * 0.92, h * 0.47, w, h * 0.505);
    pathMid.lineTo(w, h);
    pathMid.close();
    canvas.drawPath(pathMid, paintMid);

    // Luz de contorno (rim light) en la cresta intermedia: brillo atardecer.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = _sunCore.withAlpha(70);
    final rimPath = Path()
      ..moveTo(0, h * 0.505)
      ..quadraticBezierTo(w * 0.20, h * 0.455, w * 0.44, h * 0.505)
      ..quadraticBezierTo(w * 0.63, h * 0.54, w * 0.80, h * 0.495)
      ..quadraticBezierTo(w * 0.92, h * 0.47, w, h * 0.505);
    canvas.drawPath(rimPath, rim);
  }

  // ---------------------------------------------------------------------------
  // Colina cercana + plano de viñedo (fondo oscuro con follaje).
  // ---------------------------------------------------------------------------
  void _paintNearHill(Canvas canvas, double w, double h) {
    final paint = Paint()..color = _wineDeep;
    final path = Path()..moveTo(0, h);
    path.lineTo(0, h * 0.565);
    path.quadraticBezierTo(w * 0.18, h * 0.535, w * 0.40, h * 0.565);
    path.quadraticBezierTo(w * 0.62, h * 0.60, w * 0.82, h * 0.565);
    path.quadraticBezierTo(w * 0.92, h * 0.545, w, h * 0.575);
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  // ---------------------------------------------------------------------------
  // Viñedos: hileras de cepas en perspectiva sobre la loma baja.
  // Cada hilera es una curva paralela con follaje (racimos rellenos).
  // ---------------------------------------------------------------------------
  void _paintVineyard(Canvas canvas, double w, double h) {
    final rows = 7;

    for (var i = 0; i < rows; i++) {
      final t = i / (rows - 1);
      final baseY = h * (0.56 + t * 0.115);
      final canopy = Color.lerp(_wineDarker, _vineFoliage, t)!;

      // Follaje: óvalos de copa de parra espaciados a lo largo de la curva.
      final bushes = Paint()
        ..color = canopy
        ..style = PaintingStyle.fill;

      final bushCount = 8;
      final bushR = w * (0.012 + t * 0.006);

      Offset curveAt(double fx) {
        final x = w * fx;
        final y = baseY +
            (f(x, t) * w * 0.028) +
            (math.sin(fx * math.pi * 2.2 + t * 3.0) * w * 0.0035);
        return Offset(x, y);
      }

      for (var b = 0; b <= bushCount; b++) {
        final f = b / bushCount;
        final p = curveAt(f);
        // Óvalo achatado: copa de vid observada de frente.
        canvas.drawOval(
          Rect.fromCenter(
            center: p,
            width: bushR * 2.1,
            height: bushR * 1.5,
          ),
          bushes,
        );
      }

      // Poste de soporte (trazo fino por si la fila se separa visualmente).
      final post = Paint()
        ..strokeWidth = 1.0
        ..color = _wineDarker;
      for (var b = 0; b <= bushCount; b++) {
        final p = curveAt(b / bushCount);
        canvas.drawLine(
          p,
          Offset(p.dx, p.dy + w * (0.008 + t * 0.004)),
          post,
        );
      }
    }

    // Sombra de masa vegetal al borde bajo (fusión con la tarjeta).
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _wineDeep.withAlpha(0),
          _wineDeep,
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.59, w, h * 0.41));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.59, w, h * 0.41), ground);
  }

  double f(double x, double t) {
    // Curva de traslación de la hilera: ligera arruga de las filas.
    return math.sin(x * math.pi * 0.5 - t * 1.6) * 0.6;
  }

  // ---------------------------------------------------------------------------
  // Viñeta sutil para dirigir la mirada al centro.
  // ---------------------------------------------------------------------------
  void _paintVignette(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [Colors.transparent, _wineDeep.withAlpha(70)],
        stops: [0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Offset.zero & Size(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant SunsetValleyPainter oldDelegate) => false;
}