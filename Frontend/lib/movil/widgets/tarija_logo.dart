import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Wordmark ilustrado de Mesa Chapaca: la rama de vid se entrelaza con las
/// letras del nombre. Pensado para montarse sobre la escena de atardecer,
/// por eso usa crema y dorado con una sombra suave de contraste.
class TarijaLogo extends StatelessWidget {
  const TarijaLogo({super.key, this.compact = false});

  /// Ajusta tamaños para pantallas muy pequeñas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.86 : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VIÑEDOS & GASTRONOMÍA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 3.2,
                fontSize: 11 * scale,
                color: AppColors.sunset.withAlpha(235),
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'TARIJA · BOLIVIA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 3.8,
                fontSize: 9.5 * scale,
                color: Colors.white.withAlpha(180),
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
        ),
        SizedBox(height: 14 * scale),
        // Wordmark con la vid entrelazada.
        SizedBox(
          height: (compact ? 62 : 74) * scale,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final style = TextStyle(
                fontFamily: AppFonts.display,
                fontSize: (compact ? 46 : 56) * scale,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: AppColors.paper,
                letterSpacing: 1.0,
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 14),
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              );

              return Center(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          textBaseline: TextBaseline.alphabetic,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Mesa ', style: style),
                            Text(
                              'Chapaca',
                              style: style.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      // Rama de vid que atraviesa el wordmark.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _VineFlourishPainter(scale: scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20 * scale),
        // Sepador dorado con racimo cenital.
        SizedBox(
          width: 46 * scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: (18 * scale).clamp(14, 26),
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(200),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                child: const CustomPaint(
                  size: Size.square(16),
                  painter: _GrapeClusterPainter(),
                ),
              ),
              Container(
                width: (18 * scale).clamp(14, 26),
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(200),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rama de vid estilizada que cruza sobre/entre las letras del wordmark:
/// tallo en S con hojas doradas y un racimo pequeño.
class _VineFlourishPainter extends CustomPainter {
  const _VineFlourishPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Tallo principal en "S" atravesando el centro del wordmark.
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..color = AppColors.wine.withAlpha(235);

    final path = Path()
      ..moveTo(w * 0.06, h * 0.30)
      ..cubicTo(
        w * 0.20, h * 0.62,
        w * 0.42, h * 0.18,
        w * 0.62, h * 0.52,
      )
      ..cubicTo(
        w * 0.74, h * 0.70,
        w * 0.88, h * 0.40,
        w * 0.96, h * 0.20,
      );
    canvas.drawPath(path, stem);

    // Hojas doradas a lo largo del tallo.
    final leaf = Paint()..color = AppColors.gold;
    final leafS = 7.0 * scale;
    void leafAt(Offset c, double angle, double size) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: size * 2.0, height: size),
        leaf,
      );
      canvas.restore();
    }

    leafAt(Offset(w * 0.34, h * 0.34), -0.7, leafS);
    leafAt(Offset(w * 0.52, h * 0.42), 0.45, leafS * 0.85);
    leafAt(Offset(w * 0.66, h * 0.53), -0.4, leafS);
    leafAt(Offset(w * 0.80, h * 0.41), 0.85, leafS * 0.8);

    // Racimo pequeño al final del tallo.
    final grape = Paint()..color = AppColors.wine.withAlpha(200);
    final g = w * 3.6 * scale;
    final cluster = Offset(w * 0.90, h * 0.24);
    for (final off in const [
      Offset(0, 0),
      Offset(-1.1, 1.0),
      Offset(1.1, 1.0),
      Offset(0, 2.0),
      Offset(-2.2, 1.9),
      Offset(2.2, 1.9),
    ]) {
      canvas.drawCircle(
        cluster + Offset(off.dx * g * 0.18, off.dy * g * 0.18),
        g * 0.16,
        grape,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VineFlourishPainter oldDelegate) =>
      oldDelegate.scale != scale;
}

/// Racimo de uva dibujado en línea fina — firma visual de la marca.
class _GrapeClusterPainter extends CustomPainter {
  const _GrapeClusterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final r = size.width * 0.16;

    final berry = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = AppColors.gold;

    final positions = <Offset>[
      Offset(center.dx, center.dy),
      Offset(center.dx - r * 0.9, center.dy + r * 0.5),
      Offset(center.dx + r * 0.9, center.dy + r * 0.5),
      Offset(center.dx - r * 1.3, center.dy + r * 1.05),
      Offset(center.dx, center.dy + r * 1.25),
      Offset(center.dx + r * 1.3, center.dy + r * 1.05),
      Offset(center.dx - r * 0.65, center.dy + r * 1.75),
      Offset(center.dx + r * 0.65, center.dy + r * 1.75),
    ];

    for (final p in positions) {
      canvas.drawCircle(p, r * 0.44, berry);
    }

    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 1.5)
      ..quadraticBezierTo(
          center.dx + r * 0.9, center.dy - r * 1.0, center.dx, center.dy - r * 0.15);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _GrapeClusterPainter oldDelegate) => false;
}