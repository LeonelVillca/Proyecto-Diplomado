import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'components/page_one_view.dart';
import 'components/onboarding_top_bar.dart';

/// Pantalla de Onboarding de Mesa Chapaca.
///
/// Un AnimationController de duración total de 9 s gobierna todo:
///   0.0        → Página 1 visible al inicio (sin animación de entrada)
///   0.2 → 0.4  → Página 1 sale / Página 2 entra
///   0.4 → 0.6  → Página 2 sale / Página 3 entra
///   Al tocar el botón en página 3 → pushReplacement al LoginScreen
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  // Controlador exclusivo para la animación de entrada de la página 1
  late final AnimationController _entranceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  // Página actual (0, 1, 2) para saber qué mostrar en el botón
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Corre la animación de entrada automáticamente al abrir la pantalla
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Navegación ───────────────────────────────────────────────

  void _onSkipClick() {
    setState(() => _page = 2);
    _ctrl.animateTo(0.6, duration: const Duration(milliseconds: 700));
  }

  void _onBackClick() {
    if (_page == 1) {
      setState(() => _page = 0);
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 500));
    } else if (_page == 2) {
      setState(() => _page = 1);
      _ctrl.animateTo(0.2, duration: const Duration(milliseconds: 500));
    }
  }

  void _onNextClick() {
    if (_page == 0) {
      setState(() => _page = 1);
      _ctrl.animateTo(0.4, duration: const Duration(milliseconds: 600));
    } else if (_page == 1) {
      setState(() => _page = 2);
      _ctrl.animateTo(0.6, duration: const Duration(milliseconds: 600));
    } else {
      // Página 3 → ir al Login
      _goToLogin();
    }
  }

  void _goToLogin() {
    widget.onFinish();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Fondo degradado cálido ──────────────────────
              const _WarmBackground(),

              // ── Páginas animadas ────────────────────────────
              PageOneView(
                animationController: _ctrl,
                entranceCtrl: _entranceCtrl,
              ),
              PageTwoView(animationController: _ctrl),
              PageThreeView(animationController: _ctrl),

              // ── Barra superior (back, dots, skip) ───────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: OnboardingTopBar(
                    currentPage: _page,
                    animationController: _ctrl,
                    onBackClick: _onBackClick,
                    onSkipClick: _onSkipClick,
                  ),
                ),
              ),

              // ── Botón inferior central ───────────────────────
              Positioned(
                bottom: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: _ProgressButton(
                    page: _page,
                    onTap: _onNextClick,
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

// ══════════════════════════════════════════════════════════════
// Botón de progreso: flecha en páginas 1-2, "Ingresar" en página 3
// ══════════════════════════════════════════════════════════════
class _ProgressButton extends StatefulWidget {
  final int page;
  final VoidCallback onTap;
  const _ProgressButton({required this.page, required this.onTap});

  @override
  State<_ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<_ProgressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.92,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.page == 2;

    return GestureDetector(
      onTapDown: (_) => _scale.reverse(),
      onTapUp: (_) {
        _scale.forward();
        widget.onTap();
      },
      onTapCancel: () => _scale.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isLast
              // ── Última página: botón ancho con texto ────────
              ? Container(
                  key: const ValueKey('last'),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withOpacity(0.38),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ingresar a Mesa Chapaca',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
                )
              // ── Páginas 1-2: botón circular con flecha ──────
              : Container(
                  key: const ValueKey('arrow'),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withOpacity(0.38),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Fondo degradado cálido
// ══════════════════════════════════════════════════════════════
class _WarmBackground extends StatelessWidget {
  const _WarmBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFBF4E8),
            Color(0xFFF5EEE0),
            Color(0xFFF0E6D4),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.9),
            radius: 1.1,
            colors: [Color(0x33C08A1E), Color(0x00C08A1E)],
          ),
        ),
      ),
    );
  }
}
