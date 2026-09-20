import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_footer.dart';
import 'package:frontend/widgets/admin/landing_showcase.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class LandingBenefits extends StatelessWidget {
  const LandingBenefits({
    required this.howKey,
    required this.benefitsKey,
    required this.restaurantsKey,
    required this.contactKey,
    required this.onRegister,
    super.key,
  });

  final Key howKey;
  final Key benefitsKey;
  final Key restaurantsKey;
  final Key contactKey;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HowItWorks(key: howKey),
        _Benefits(key: benefitsKey, onRegister: onRegister),
        LandingShowcase(onRegister: onRegister),
        _RestaurantStories(key: restaurantsKey),
        const _ProofStrip(),
        LandingFooter(key: contactKey, onRegister: onRegister),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      color: LandingPalette.paperDeep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900 ? 3 : (width >= 580 ? 2 : 1);
          final gap = 20.0;
          final cardWidth = (width - gap * (columns - 1)) / columns;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionMarker('Cómo funciona'),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'De la solicitud a tu primera reserva.',
                  style: LandingType.heading(size: width < 600 ? 34 : 46),
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Text(
                  'Un proceso claro, acompañado por nuestro equipo y sin cambiar la forma en que atiendes a tus clientes.',
                  style: LandingType.bodyText(size: 17),
                ),
              ),
              const SizedBox(height: 44),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _StepCard(
                    width: cardWidth,
                    number: '01',
                    icon: Icons.description_outlined,
                    title: 'Envía tu solicitud',
                    description:
                        'Cuéntanos sobre tu restaurante. Revisamos la información en menos de 24 horas.',
                  ),
                  _StepCard(
                    width: cardWidth,
                    number: '02',
                    icon: Icons.verified_outlined,
                    title: 'Prepara tu espacio',
                    description:
                        'Configura mesas, horarios, fotografías y menú con acompañamiento inicial.',
                  ),
                  _StepCard(
                    width: cardWidth,
                    number: '03',
                    icon: Icons.table_restaurant_outlined,
                    title: 'Recibe reservas',
                    description:
                        'Confirma solicitudes en tiempo real y mantén a tu equipo coordinado.',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.width,
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso $number: $title. $description',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LandingPalette.card,
              border: Border.all(color: LandingPalette.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        number,
                        style: LandingType.heading(
                          size: 28,
                          color: LandingPalette.wine,
                        ),
                      ),
                      Icon(icon, color: LandingPalette.gold, size: 28),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    style: LandingType.bodyText(
                      size: 18,
                      color: LandingPalette.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(description, style: LandingType.bodyText()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.onRegister, super.key});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      color: LandingPalette.paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final desktop = width >= 860;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionMarker('Una operación más tranquila', onDark: true),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Todo tu salón en una sola vista.',
                  style: LandingType.heading(
                    size: width < 600 ? 36 : 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Menos llamadas cruzadas. Más claridad para decidir qué mesa está disponible y qué necesita cada reserva.',
                style: LandingType.bodyText(
                  size: 17,
                  color: const Color(0xFFE9DDE2),
                ),
              ),
              const SizedBox(height: 28),
              const _BenefitItem(
                icon: Icons.event_available_outlined,
                title: 'Reservas en tiempo real',
                description:
                    'Consulta, confirma y organiza cada llegada desde el panel.',
              ),
              const _BenefitItem(
                icon: Icons.menu_book_outlined,
                title: 'Menú siempre actualizado',
                description:
                    'Publica platos, precios y fotografías sin depender de impresiones.',
              ),
              const _BenefitItem(
                icon: Icons.travel_explore_outlined,
                title: 'Más fácil de descubrir',
                description:
                    'Presenta tu propuesta a comensales locales y visitantes.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: LandingPalette.wine,
                  minimumSize: const Size(48, 52),
                  textStyle: LandingType.bodyText(
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                child: const Text('Solicitar acceso para mi restaurante'),
              ),
            ],
          );
          const visual = _FoodVisual();
          return DecoratedBox(
            decoration: BoxDecoration(
              color: LandingPalette.wineDeep,
              borderRadius: BorderRadius.circular(width < 600 ? 24 : 36),
              border: Border.all(color: const Color(0x55B98324)),
            ),
            child: Padding(
              padding: EdgeInsets.all(width < 600 ? 24 : 48),
              child: desktop
                  ? Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 52),
                        const Expanded(child: visual),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [copy, const SizedBox(height: 40), visual],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LandingPalette.gold, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LandingType.bodyText(
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: LandingType.bodyText(
                    size: 15,
                    color: const Color(0xFFD7C8CE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodVisual extends StatelessWidget {
  const _FoodVisual();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Selección de platos inspirados en la gastronomía boliviana',
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(80),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(80),
          ),
          child: Image.asset(
            'assets/tarija_food_optimized.jpg',
            fit: BoxFit.cover,
            width: 640,
            height: 640,
            cacheWidth: 900,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: LandingPalette.wine),
          ),
        ),
      ),
    );
  }
}

class _RestaurantStories extends StatelessWidget {
  const _RestaurantStories({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      color: LandingPalette.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
          final gap = 20.0;
          final cardWidth = (width - gap * (columns - 1)) / columns;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionMarker('Restaurantes que avanzan'),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Más tiempo para recibir. Menos tiempo coordinando.',
                  style: LandingType.heading(size: width < 600 ? 34 : 46),
                ),
              ),
              const SizedBox(height: 44),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _QuoteCard(
                    width: cardWidth,
                    quote:
                        'Las reservas llegan ordenadas y el equipo sabe qué preparar antes de cada servicio.',
                    name: 'Carlos Montaño',
                    restaurant: 'La Casona Tarijeña',
                  ),
                  _QuoteCard(
                    width: cardWidth,
                    quote:
                        'Actualizar el menú y organizar las mesas ahora toma minutos, incluso desde el teléfono.',
                    name: 'María Flores',
                    restaurant: 'El Viñedo del Sur',
                  ),
                  _QuoteCard(
                    width: cardWidth,
                    quote:
                        'Podemos responder reseñas y entender mejor lo que nuestros clientes valoran.',
                    name: 'Roberto Vega',
                    restaurant: 'Rincón Criollo',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.width,
    required this.quote,
    required this.name,
    required this.restaurant,
  });
  final double width;
  final String quote;
  final String name;
  final String restaurant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: LandingPalette.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LandingPalette.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Calificación: cinco de cinco',
                child: const ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.gold,
                        size: 19,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.gold,
                        size: 19,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.gold,
                        size: 19,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.gold,
                        size: 19,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.gold,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '“$quote”',
                style: LandingType.heading(
                  size: 22,
                  weight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                name,
                style: LandingType.bodyText(
                  color: LandingPalette.ink,
                  weight: FontWeight.w700,
                ),
              ),
              Text(restaurant, style: LandingType.bodyText(size: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofStrip extends StatelessWidget {
  const _ProofStrip();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ColoredBox(
          color: LandingPalette.wine,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LandingLayout.horizontalPadding(width),
              vertical: width < 600 ? 48 : 64,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LandingLayout.maxWidth,
                ),
                child: const Wrap(
                  alignment: WrapAlignment.spaceAround,
                  runAlignment: WrapAlignment.center,
                  spacing: 48,
                  runSpacing: 30,
                  children: [
                    _Proof(value: '50+', label: 'restaurantes afiliados'),
                    _Proof(value: '1.200+', label: 'reservas gestionadas'),
                    _Proof(value: '4,9/5', label: 'valoración promedio'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Proof extends StatelessWidget {
  const _Proof({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Text(
            value,
            style: LandingType.heading(size: 42, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: LandingType.bodyText(
              size: 15,
              color: const Color(0xFFF3E7EC),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ColoredBox(
          color: color,
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
