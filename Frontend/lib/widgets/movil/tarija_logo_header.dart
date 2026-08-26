import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';

/// Cabecera editorial: wordmark "Mesa Chapaca" con el racimo de uva como
/// firma de marca y una línea dorada de separación.
class TarijaLogoHeader extends StatelessWidget {
  const TarijaLogoHeader({
    super.key,
    this.compact = false,
    this.showTagline = true,
  });

  /// Reduce tamaños para pantallas pequeñas.
  final bool compact;

  /// Muestra la frase de valor debajo del título.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 40.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frase superior — carácter editorial
        Text(
          'VIÑEDOS & GASTRONOMÍA · TARIJA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2.6,
                color: AppColors.gold,
              ),
        ),
        const SizedBox(height: 14),
        // Wordmark mano alzada de Bodoni
        Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Mesa Chapaca',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: titleSize,
                  height: 1.0,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.wine,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CustomPaint(
              size: Size.square(compact ? 20 : 24),
              painter: const _GrapeClusterPainter(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Línea dorada divisoria
        Container(
          width: 72,
          height: 2,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        if (showTagline)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Los mejores restaurantes de Tarija, '
              'a una reserva de distancia.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: AppFonts.body,
                    fontSize: 16.5,
                    height: 1.55,
                    color: AppColors.ink,
                  ),
            ),
          ),
      ],
    );
  }
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
      ..strokeWidth = 1.1
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

    // Hoja simple sobre el tallo.
    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 1.5)
      ..quadraticBezierTo(center.dx + r * 0.9, center.dy - r * 1.0, center.dx, center.dy - r * 0.15);
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