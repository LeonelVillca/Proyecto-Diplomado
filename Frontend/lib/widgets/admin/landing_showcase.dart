import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class LandingShowcase extends StatelessWidget {
  const LandingShowcase({required this.onRegister, super.key});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _ShowcaseShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < 700;
          final cardWidth = compact ? width : (width - 32) / 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionMarker('La experiencia empieza antes de la reserva'),
              const SizedBox(height: 16),
              Text(
                'Un perfil que se siente como tu restaurante.',
                style: LandingType.heading(size: compact ? 34 : 46),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Muestra tu cocina, tu ambiente y la forma en que recibes a tus clientes desde un solo lugar.',
                  style: LandingType.bodyText(size: 17),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ShowcaseCard(
                    width: cardWidth,
                    image: 'assets/tarija_food_optimized.webp',
                    label: 'Tu propuesta',
                    title: 'Haz visible lo que te hace especial.',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  _ShowcaseCard(
                    width: cardWidth,
                    image: 'assets/dining_couple_optimized.webp',
                    label: 'Tu ambiente',
                    title: 'Convierte una visita en una experiencia.',
                    icon: Icons.wine_bar_rounded,
                  ),
                  _ShowcaseCard(
                    width: cardWidth,
                    image: 'assets/aaa.webp',
                    label: 'Tu operación',
                    title: 'Coordina cada servicio con claridad.',
                    icon: Icons.event_available_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Quiero presentar mi restaurante'),
                style: FilledButton.styleFrom(
                  backgroundColor: LandingPalette.wine,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  textStyle: LandingType.bodyText(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShowcaseShell extends StatelessWidget {
  const _ShowcaseShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ColoredBox(
          color: LandingPalette.paper,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LandingLayout.horizontalPadding(width),
              vertical: LandingLayout.sectionPadding(width),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LandingLayout.maxWidth,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.width,
    required this.image,
    required this.label,
    required this.title,
    required this.icon,
  });

  final double width;
  final String image;
  final String label;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LandingPalette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: LandingPalette.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: 640,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: LandingPalette.wineDeep),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: LandingPalette.terracotta),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: LandingType.bodyText(
                            size: 13,
                            color: LandingPalette.terracotta,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: LandingType.bodyText(
                        size: 18,
                        color: LandingPalette.ink,
                        weight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
