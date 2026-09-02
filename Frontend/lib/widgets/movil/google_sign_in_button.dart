import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';

/// Botón estilizado e independiente de "Continuar con Google".
/// Fondo blanco, sombra suave en capas, la "G" oficial (asset con fallback
/// al glifo vectorial) y tipografía Montserrat moderna.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  /// Acción al presionar el botón (debe inhabilitarse cuando [isLoading]).
  final VoidCallback onPressed;

  /// Muestra un indicador de progreso y bloquea el botón.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (isLoading) {
      return const _GoogleButtonSurface(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.wine,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: _GoogleButtonSurface(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleLogo(size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Continuar con Google',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.googleInk,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Superficie blanca de Google con sombra suave y borde sutil.
class _GoogleButtonSurface extends StatelessWidget {
  const _GoogleButtonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.googleButton,
      ),
      child: Center(child: child),
    );
  }
}

/// Logo de Google. Prioriza el asset oficial [GoogleGLogo] si no está.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google_icon.png',
      width: size,
      height: size,
      errorBuilder: (context, _, _) => GoogleGLogo(size: size),
    );
  }
}

/// Logo oficial de Google (las cuatro "G") dibujado a código.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  // Trazos oficiales del glifo "G" de Google (viewBox 24x24).
  static const _paths = <String, Color>{
    'M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 '
        '2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z':
        Color(0xFF4285F4),
    'M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 '
        '1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z':
        Color(0xFF34A853),
    'M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18'
        'C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z':
        Color(0xFFFBBC05),
    'M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 '
        '7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z':
        Color(0xFFEA4335),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    for (final entry in _paths.entries) {
      final path = SvgPathParser.toPath(entry.key, scale);
      canvas.drawPath(path, Paint()..color = entry.value);
    }
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}

/// Parser mínimo de SVG que cubre los comandos del glifo "G":
/// M, L, C, S, H, V, Z (y sus variantes relativas).
class SvgPathParser {
  const SvgPathParser._();

  static Path toPath(String svg, double scale) {
    final tokens = RegExp(r'-?\d*\.?\d+|[A-Za-z]').allMatches(svg).toList();

    final path = Path()..fillType = PathFillType.nonZero;
    double x = 0, y = 0;
    double prevCtrlX = 0, prevCtrlY = 0;
    var hadCtrl = false;
    var i = 0;
    var cmd = 'M';

    double read(int index) => double.parse(tokens[index].group(0)!) * scale;

    bool isCommand(String token) => RegExp(r'[A-Za-z]').hasMatch(token);

    while (i < tokens.length) {
      if (isCommand(tokens[i].group(0)!)) {
        cmd = tokens[i].group(0)!;
        i++;
        continue;
      }

      final rel = cmd != cmd.toUpperCase();
      final dx = rel ? x : 0.0;
      final dy = rel ? y : 0.0;

      switch (cmd.toUpperCase()) {
        case 'M':
          x = read(i) + dx;
          y = read(i + 1) + dy;
          path.moveTo(x, y);
          hadCtrl = false;
          i += 2;
          break;
        case 'L':
          x = read(i) + dx;
          y = read(i + 1) + dy;
          path.lineTo(x, y);
          hadCtrl = false;
          i += 2;
          break;
        case 'C':
          final c1x = read(i) + dx;
          final c1y = read(i + 1) + dy;
          final c2x = read(i + 2) + dx;
          final c2y = read(i + 3) + dy;
          x = read(i + 4) + dx;
          y = read(i + 5) + dy;
          path.cubicTo(c1x, c1y, c2x, c2y, x, y);
          prevCtrlX = c2x;
          prevCtrlY = c2y;
          hadCtrl = true;
          i += 6;
          break;
        case 'S':
          final c1x = hadCtrl ? 2 * x - prevCtrlX : x;
          final c1y = hadCtrl ? 2 * y - prevCtrlY : y;
          final c2x = read(i) + dx;
          final c2y = read(i + 1) + dy;
          x = read(i + 2) + dx;
          y = read(i + 3) + dy;
          path.cubicTo(c1x, c1y, c2x, c2y, x, y);
          prevCtrlX = c2x;
          prevCtrlY = c2y;
          hadCtrl = true;
          i += 4;
          break;
        case 'H':
          x = read(i) + dx;
          path.lineTo(x, y);
          hadCtrl = false;
          i += 1;
          break;
        case 'V':
          y = read(i) + dy;
          path.lineTo(x, y);
          hadCtrl = false;
          i += 1;
          break;
        case 'Z':
          path.close();
          i += 0;
          break;
        default:
          throw ArgumentError('Comando SVG no soportado: "$cmd"');
      }
    }

    return path;
  }
}