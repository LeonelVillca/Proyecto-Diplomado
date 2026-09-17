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
      duration: const Duration(milliseconds: 560),
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
          final desktop = width >= 920;
          final horizontal = LandingLayout.horizontalPadding(width);
          final content = desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _HeroCopy(widget: widget, width: width),
                    ),
                    const SizedBox(width: 56),
                    const Expanded(child: _HeroVisual()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCopy(widget: widget, width: width),
                    const SizedBox(height: 44),
                    const _HeroVisual(),
                  ],
                );

          return ColoredBox(
            color: LandingPalette.paper,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                desktop ? 156 : 128,
                horizontal,
                LandingLayout.sectionPadding(width),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LandingLayout.maxWidth,
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.025),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.widget, required this.width});
  final LandingHero widget;
  final double width;

  @override
  Widget build(BuildContext context) {
    final compact = width < LandingLayout.tablet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionMarker('Reservas y gestión para la mesa tarijeña'),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            'Tu restaurante, listo para recibir más comensales.',
            style: LandingType.heading(size: compact ? 42 : 58),
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Centraliza reservas, mesas y menú digital en una plataforma creada para restaurantes de Tarija.',
            style: LandingType.bodyText(size: compact ? 17 : 19),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: widget.onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: LandingPalette.wine,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: LandingType.bodyText(
                  size: 16,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Registrar mi restaurante'),
            ),
            OutlinedButton(
              onPressed: widget.onExplore,
              style: OutlinedButton.styleFrom(
                foregroundColor: LandingPalette.wine,
                side: const BorderSide(color: LandingPalette.wine),
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                textStyle: LandingType.bodyText(
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
              child: const Text('Conocer la plataforma'),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _TrustPoint(
              icon: Icons.schedule_rounded,
              text: 'Reservas en tiempo real',
            ),
            _TrustPoint(
              icon: Icons.phone_android_rounded,
              text: 'Panel desde cualquier dispositivo',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.02,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LandingPalette.wineDeep,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(96),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(96),
                ),
                border: Border.all(color: LandingPalette.gold, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332A1020),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(94),
                  topRight: Radius.circular(26),
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(94),
                ),
                child: Semantics(
                  image: true,
                  label: 'Mesa preparada en un restaurante de ambiente cálido',
                  child: Image.asset(
                    'assets/restaurant_hero_optimized.jpg',
                    fit: BoxFit.cover,
                    width: 720,
                    height: 720,
                    cacheWidth: 960,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: LandingPalette.wineDeep),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(left: -16, bottom: 36, child: _ReservationCard()),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Ejemplo: reserva confirmada para cuatro personas hoy a las ocho de la noche',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 270),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LandingPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LandingPalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332A1020),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE4EEE3),
                foregroundColor: LandingPalette.leaf,
                child: Icon(Icons.check_rounded),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reserva confirmada',
                    style: LandingType.bodyText(
                      color: LandingPalette.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '4 personas · Hoy, 20:00',
                    style: LandingType.bodyText(size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: LandingPalette.leaf),
        const SizedBox(width: 8),
        Text(
          text,
          style: LandingType.bodyText(
            size: 14,
            color: LandingPalette.ink,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
