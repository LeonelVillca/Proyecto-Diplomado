import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';

// ══════════════════════════════════════════════════════════════
// PÁGINA 1 — Descubrir
// Tiene dos controladores:
//   • entranceCtrl → animación de entrada que corre una sola vez al inicio
//   • animationController → controla cuándo sale (0.2 → 0.4)
// ══════════════════════════════════════════════════════════════
class PageOneView extends StatelessWidget {
  final AnimationController animationController;
  final AnimationController entranceCtrl;

  const PageOneView({
    Key? key,
    required this.animationController,
    required this.entranceCtrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ── Salida hacia la izquierda (0.2 → 0.4) ─────────────────
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
    ));

    final imageOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.6, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
    ));

    // ── Animaciones de ENTRADA escalonadas (entranceCtrl) ──────

    // Imagen: sube desde abajo con rebote (0.0 → 0.55)
    final imgEntrance = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    final imgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Tag: aparece un poco después (0.25 → 0.65)
    final tagEntrance = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    ));
    final tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    // Título: entra después del tag (0.40 → 0.80)
    final titleEntrance = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.4, 0.80, curve: Curves.easeOutCubic),
    ));
    final titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.4, 0.72, curve: Curves.easeOut),
      ),
    );

    // Subtítulo: el último en aparecer (0.55 → 1.0)
    final subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    final subEntrance = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    return SlideTransition(
      position: slideOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 160),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Imagen ─────────────────────────────────────────
            FadeTransition(
              opacity: imgFade,
              child: SlideTransition(
                position: imgEntrance,
                child: SlideTransition(
                  position: imageOut,
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 300, maxHeight: 280),
                    child: Image.asset('assets/uno.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ── Tag ────────────────────────────────────────────
            FadeTransition(
              opacity: tagFade,
              child: SlideTransition(
                position: tagEntrance,
                child: _TagChip(
                  label: 'DESCUBRIMIENTO',
                  color: AppColors.wine,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Título ─────────────────────────────────────────
            FadeTransition(
              opacity: titleFade,
              child: SlideTransition(
                position: titleEntrance,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Explora los\nmejores sabores',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppColors.wine,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Línea de acento ────────────────────────────────
            FadeTransition(
              opacity: titleFade,
              child: Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Subtítulo ──────────────────────────────────────
            FadeTransition(
              opacity: subFade,
              child: SlideTransition(
                position: subEntrance,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    'Los restaurantes y vinotecas más auténticos de Tarija, seleccionados para ti.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.65,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PÁGINA 2 — Reservar
// ══════════════════════════════════════════════════════════════
class PageTwoView extends StatelessWidget {
  final AnimationController animationController;
  const PageTwoView({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
    ));

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
    ));

    final imageOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.6, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
    ));

    return SlideTransition(
      position: slideIn,
      child: SlideTransition(
        position: slideOut,
        child: _PageContent(
          tag: 'RESERVAS',
          title: 'Tu mesa,\na un toque',
          subtitle:
              'Reserva en segundos. Elige fecha, hora y personas. Sin filas ni llamadas.',
          imagePath: 'assets/2.png',
          accentColor: AppColors.terracotta,
          imageSlide: imageOut,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PÁGINA 3 — Disfrutar
// ══════════════════════════════════════════════════════════════
class PageThreeView extends StatelessWidget {
  final AnimationController animationController;
  const PageThreeView({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
    ));

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.7, 0.8, curve: Curves.easeInOut),
    ));

    final imageOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.6, 0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.7, 0.8, curve: Curves.easeInOut),
    ));

    return SlideTransition(
      position: slideIn,
      child: SlideTransition(
        position: slideOut,
        child: _PageContent(
          tag: 'EXPERIENCIA',
          title: 'Vive momentos\nque perduran',
          subtitle:
              'Comparte una velada perfecta con los mejores vinos y platillos de la región.',
          imagePath: 'assets/tres.png',
          accentColor: AppColors.gold,
          imageSlide: imageOut,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Layout reutilizable para páginas 2 y 3
// ══════════════════════════════════════════════════════════════
class _PageContent extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accentColor;
  final Animation<Offset> imageSlide;

  const _PageContent({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
    required this.imageSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideTransition(
            position: imageSlide,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300, maxHeight: 280),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 40),

          _TagChip(label: tag, color: accentColor),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.wine,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.65,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widget compartido: chip de categoría
// ══════════════════════════════════════════════════════════════
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.4,
          color: color,
        ),
      ),
    );
  }
}
