import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class LandingHero extends StatefulWidget {
  const LandingHero({
    required this.onRegister,
    required this.onExplore,
    super.key,
  });

  final VoidCallback onRegister;
  final VoidCallback onExplore;

  @override
  State<LandingHero> createState() => _LandingHeroState();
}

class _LandingHeroState extends State<LandingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Presentación de Mesa Chapaca',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final desktop = width >= 960;
          final wide = width >= 1180;
          final horizontal = LandingLayout.horizontalPadding(width);
          final minHeight = desktop ? 790.0 : 930.0;
          final entrance = CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          );

          return ClipRect(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: entrance,
                        builder: (context, child) => Transform.scale(
                          scale: 1.035 - (entrance.value * 0.035),
                          child: child,
                        ),
                        child: Image.asset(
                          'assets/mesa_chapaca_hero_2026.webp',
                          fit: BoxFit.cover,
                          alignment: desktop
                              ? Alignment.center
                              : Alignment.centerRight,
                          cacheWidth: desktop ? 2048 : 1000,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: LandingPalette.wineDeep),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: desktop
                              ? const [
                                  Color(0xFA16070C),
                                  Color(0xE3240B15),
                                  Color(0x98310916),
                                  Color(0x22000000),
                                ]
                              : const [
                                  Color(0xF518080E),
                                  Color(0xE8310916),
                                  Color(0xA6310916),
                                ],
                          stops: desktop
                              ? const [0, .38, .66, 1]
                              : const [0, .68, 1],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0x00000000),
                            Color(0xCC12070B),
                          ],
                          stops: [0, .62, 1],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      desktop ? 152 : 126,
                      horizontal,
                      42,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: LandingLayout.maxWidth,
                        ),
                        child: FadeTransition(
                          opacity: entrance,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .035),
                              end: Offset.zero,
                            ).animate(entrance),
                            child: SizedBox(
                              height: minHeight - (desktop ? 194 : 168),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _HeroCopy(widget: widget, compact: !desktop),
                                  const Spacer(),
                                  const _HeroFeatureRail(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (wide)
                    Positioned(
                      right: horizontal,
                      top: 198,
                      child: FadeTransition(
                        opacity: entrance,
                        child: const _LivePanel(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.widget, required this.compact});
  final LandingHero widget;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 650 : 690),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: LandingPalette.wine,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hecho para la gastronomía de Tarija',
                    style: LandingType.bodyText(
                      size: 13,
                      color: LandingPalette.wineDeep,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compact ? 24 : 30),
          Semantics(
            header: true,
            child: Text(
              'Tu restaurante merece una mesa llena.',
              style: LandingType.heading(
                size: compact ? 48 : 70,
                color: Colors.white,
                weight: FontWeight.w700,
                height: 1.02,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Crea un perfil que abra el apetito, organiza tus reservas y convierte cada visita en una experiencia que quieran repetir.',
            style: LandingType.bodyText(
              size: compact ? 17 : 20,
              color: const Color(0xFFF4EDEF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: widget.onRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: LandingPalette.gold,
                  foregroundColor: LandingPalette.wineDeep,
                  minimumSize: const Size(48, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  textStyle: LandingType.bodyText(
                    size: 16,
                    color: LandingPalette.wineDeep,
                    weight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: const Text('Crear el perfil de mi restaurante'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onExplore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x99FFFFFF)),
                  backgroundColor: const Color(0x22000000),
                  minimumSize: const Size(48, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  textStyle: LandingType.bodyText(
                    size: 16,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: const Text('Descubrir cómo funciona'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFeatureRail extends StatelessWidget {
  const _HeroFeatureRail();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB51C0A10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Wrap(
          spacing: 30,
          runSpacing: 18,
          children: [
            _HeroFeature(
              icon: Icons.visibility_outlined,
              title: 'Más visible',
              detail: 'Un perfil que muestra tu esencia',
            ),
            _HeroFeature(
              icon: Icons.event_available_outlined,
              title: 'Más orden',
              detail: 'Reservas y mesas en un solo lugar',
            ),
            _HeroFeature(
              icon: Icons.favorite_border_rounded,
              title: 'Más cercano',
              detail: 'Una experiencia simple para tus clientes',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: LandingPalette.sun, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LandingType.bodyText(
                    size: 15,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: LandingType.bodyText(
                    size: 13,
                    color: const Color(0xFFD6C9CD),
                    height: 1.25,
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

class _LivePanel extends StatelessWidget {
  const _LivePanel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vista ilustrativa de la actividad del restaurante',
      child: ExcludeSemantics(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xEFFFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x66FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: LandingPalette.leaf,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Actividad de hoy',
                    style: LandingType.bodyText(
                      size: 14,
                      color: LandingPalette.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: LandingPalette.muted,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _PanelMetric(
                icon: Icons.check_circle_rounded,
                color: LandingPalette.leaf,
                title: 'Reserva confirmada',
                detail: '4 personas · 20:00',
              ),
              const SizedBox(height: 14),
              const _PanelMetric(
                icon: Icons.table_restaurant_rounded,
                color: LandingPalette.terracotta,
                title: 'Mesa preparada',
                detail: 'Salón principal · Mesa 06',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelMetric extends StatelessWidget {
  const _PanelMetric({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: LandingType.bodyText(
                  size: 14,
                  color: LandingPalette.ink,
                  weight: FontWeight.w700,
                ),
              ),
              Text(detail, style: LandingType.bodyText(size: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
