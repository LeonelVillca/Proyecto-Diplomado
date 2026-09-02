import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';

/// Botón de progreso central con 3 estados:
///   • Páginas 1-2  → Flecha hacia la derecha (avanzar)
///   • Página 3     → Texto "Comenzar" + botón de acción completo
///   • Skip / Back  → Manejados por la barra superior (no este widget)
class OnboardingNextButton extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onNextClick;
  final VoidCallback onGetStartedClick;

  const OnboardingNextButton({
    Key? key,
    required this.animationController,
    required this.onNextClick,
    required this.onGetStartedClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // El botón de flecha aparece en las páginas 1 y 2 (0.0 → 0.6)
    final arrowVisible = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
      ),
    );

    // El botón grande "Comenzar" aparece solo en la última página (0.6 → 0.8)
    final startFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    final startSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.6, 0.85, curve: Curves.easeOutCubic),
    ));

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final value = animationController.value;

        // ── Página 3: botón grande "Comenzar" ──
        if (value >= 0.6) {
          return Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: FadeTransition(
              opacity: startFade,
              child: SlideTransition(
                position: startSlide,
                child: _GetStartedButton(onTap: onGetStartedClick),
              ),
            ),
          );
        }

        // ── Páginas 1 y 2: botón circular con flecha ──
        return Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: FadeTransition(
              opacity: arrowVisible,
              child: GestureDetector(
                onTap: onNextClick,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Botón de "Comenzar" de la última pantalla
// ──────────────────────────────────────────────────────────────
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón principal
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: _pressed ? AppColors.wineDark : AppColors.wine,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.wine.withOpacity(0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Comenzar ahora',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Pie de página legal
        Text(
          'Al continuar aceptas nuestros Términos de Uso\ny Política de Privacidad.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 11.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
