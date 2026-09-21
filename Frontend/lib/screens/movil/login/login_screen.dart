import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/widgets/movil/auth_bottom_card.dart';

/// Pantalla de inicio de sesión — Mesa Chapaca.
///
/// Diseño premium de dos capas:
///   • Fondo hero con la foto de Tarija + scrim gradiente oscuro.
///   • Tres orbes flotantes animados (decoración viva, no estática).
///   • Branding centrado con Piazzolla italic + Manrope para el subtítulo.
///   • Tarjeta glassmorphism inferior con la acción de Google.
///
/// Animación en cascada (900 ms):
///   0 %–40 % → logo + marca
///   20 %–70 % → tagline + divisor
///   45 %–100 % → tarjeta sube desde abajo
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controlador principal de entrada ─────────────────────────
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // ── Orbes flotantes (loop continuo) ──────────────────────────
  late final AnimationController _orbs = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  // Intervalos de la animación de entrada
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<Offset> _logoSlide = Tween<Offset>(
    begin: const Offset(0, -0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _tagFade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
  );
  late final Animation<Offset> _tagSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardSlide = Tween<Offset>(
    begin: const Offset(0, 0.22),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
  ));

  @override
  void dispose() {
    _entry.dispose();
    _orbs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.wineDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Foto hero de Tarija ────────────────────────
            Image.asset(
              'assets/fondo_tarija.webp',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
            ),

            // ── 2. Scrim gradiente multicapa ─────────────────
            const _MultiScrim(),

            // ── 3. Orbes flotantes decorativos ───────────────
            _FloatingOrbs(controller: _orbs, size: size),

            // ── 4. Contenido principal ────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Espacio superior + branding
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo con halo animado
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: const _LogoWithHalo(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Nombre de la app
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: const _BrandTitle(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Divisor + tagline
                        FadeTransition(
                          opacity: _tagFade,
                          child: SlideTransition(
                            position: _tagSlide,
                            child: const _TaglineSection(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tarjeta glass inferior
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: AuthBottomCard(auth: auth),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Scrim gradiente en múltiples capas para máximo contraste
// ──────────────────────────────────────────────────────────────
class _MultiScrim extends StatelessWidget {
  const _MultiScrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Capa 1: oscurece uniformemente la foto
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.wineDark.withAlpha(110),
          ),
        ),
        // Capa 2: gradiente de branding arriba
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, 0.35),
              colors: [Color(0xCC450B20), Colors.transparent],
            ),
          ),
        ),
        // Capa 3: gradiente fuerte abajo para la tarjeta
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0, 0.45),
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xF5100818)],
            ),
          ),
        ),
        // Capa 4: viñeta lateral sutil
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Colors.transparent, Color(0x44000000)],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Orbes flotantes — vida y dinamismo sin distracción
// ──────────────────────────────────────────────────────────────
class _FloatingOrbs extends StatelessWidget {
  const _FloatingOrbs({required this.controller, required this.size});

  final AnimationController controller;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Orbe 1 — esquina superior izquierda, dorado
            Positioned(
              left: -40 + 18 * math.sin(t * math.pi),
              top: size.height * 0.06 + 12 * math.cos(t * math.pi),
              child: _Orb(
                size: 160,
                color: AppColors.gold.withAlpha(35),
              ),
            ),
            // Orbe 2 — derecha media, terracota
            Positioned(
              right: -50 + 14 * math.cos(t * math.pi * 1.3),
              top: size.height * 0.3 + 20 * math.sin(t * math.pi * 0.9),
              child: _Orb(
                size: 130,
                color: AppColors.terracotta.withAlpha(28),
              ),
            ),
            // Orbe 3 — centro inferior, vino suave
            Positioned(
              left: size.width * 0.2 + 10 * math.sin(t * math.pi * 1.1),
              top: size.height * 0.55 + 8 * math.cos(t * math.pi * 1.4),
              child: _Orb(
                size: 100,
                color: AppColors.wineSoft.withAlpha(22),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Logo con halo pulsante de color vino/dorado
// ──────────────────────────────────────────────────────────────
class _LogoWithHalo extends StatelessWidget {
  const _LogoWithHalo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo exterior
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.gold.withAlpha(55),
                AppColors.wineSoft.withAlpha(25),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Contenedor del logo
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(15),
            border: Border.all(
              color: Colors.white.withAlpha(45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withAlpha(80),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/icon_app.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Título principal — Piazzolla italic (display font del tema)
// ──────────────────────────────────────────────────────────────
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow — Manrope spaced caps
        Text(
          'BIENVENIDO A',
          style: GoogleFonts.poppins (
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.5,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 10),
        // Wordmark — Piazzolla italic grande
        Text(
          'Mesa Chapaca',
          style: GoogleFonts.piazzolla(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                color: AppColors.wine.withAlpha(180),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Divisor ornamental + tagline — Manrope light
// ──────────────────────────────────────────────────────────────
class _TaglineSection extends StatelessWidget {
  const _TaglineSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divisor ornamental
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold.withAlpha(160),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(120),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withAlpha(160),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tagline
          Text(
            'Descubre y reserva en los mejores\nrestaurantes de Tarija',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Colors.white.withAlpha(180),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
