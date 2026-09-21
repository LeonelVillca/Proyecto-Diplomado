import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class LandingNavbar extends StatefulWidget {
  const LandingNavbar({
    this.onBenefits,
    this.onHowItWorks,
    this.onRestaurants,
    this.onContact,
    this.onLogin,
    this.onRegister,
    this.showLinks = true,
    this.pageTitle,
    super.key,
  });

  final VoidCallback? onBenefits;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onRestaurants;
  final VoidCallback? onContact;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final bool showLinks;
  final String? pageTitle;

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar> {
  bool _menuOpen = false;

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < LandingLayout.desktop;
        final mobile = width <= 640;
        
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.fromLTRB(22, 10, mobile ? 8 : 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(242), // ~0.95 alpha
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: LandingPalette.line.withAlpha(230)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const _Brand(compact: true),
                      if (widget.showLinks) ...[
                        // Modo landing completo: links de navegacion + botones auth
                        if (!mobile) ...[
                          const Spacer(),
                          if (!compact)
                            _NavLinks(
                              onBenefits: widget.onBenefits,
                              onHowItWorks: widget.onHowItWorks,
                              onRestaurants: widget.onRestaurants,
                              onContact: widget.onContact,
                            ),
                          const Spacer(),
                          if (!compact)
                            TextButton(
                              onPressed: widget.onLogin,
                              style: TextButton.styleFrom(
                                foregroundColor: LandingPalette.ink,
                                textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w600),
                              ),
                              child: const Text('Iniciar sesion'),
                            ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: widget.onRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: LandingPalette.wine,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
                              textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w600, color: Colors.white),
                            ),
                            child: Text(compact ? 'Registrar' : 'Registrar mi restaurante'),
                          ),
                        ] else ...[
                          const Spacer(),
                          TextButton(
                            onPressed: widget.onLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: LandingPalette.ink,
                              textStyle: LandingType.bodyText(size: 14, weight: FontWeight.w600),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Entrar'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: widget.onRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: LandingPalette.wine,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w600, color: Colors.white),
                            ),
                            child: const Text('Registrar'),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: _toggleMenu,
                            icon: Icon(
                              _menuOpen ? Icons.close : Icons.menu,
                              color: LandingPalette.ink,
                              size: 24,
                            ),
                          ),
                        ],
                      ] else ...[
                        // Modo pagina interna: solo badge de titulo + boton volver
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: LandingPalette.wine.withAlpha(15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: LandingPalette.wine.withAlpha(40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: LandingPalette.wine, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                widget.pageTitle ?? 'Mesa Chapaca',
                                style: LandingType.bodyText(size: 12, color: LandingPalette.wine, weight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: widget.onLogin,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Volver al inicio'),
                          style: TextButton.styleFrom(
                            foregroundColor: LandingPalette.muted,
                            textStyle: LandingType.bodyText(size: 14, weight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ],
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

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/icon_app.webp',
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            fit: BoxFit.cover,
            cacheWidth: compact ? 72 : 84,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                color: LandingPalette.wine,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Mesa Chapaca',
          style: LandingType.heading(
            size: compact ? 18 : 20,
            weight: FontWeight.w700,
            color: LandingPalette.ink,
          ),
        ),
      ],
    );
  }
}

class _NavLinks extends StatelessWidget {
  const _NavLinks({this.onBenefits, this.onHowItWorks, this.onRestaurants, this.onContact});
  final VoidCallback? onBenefits;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onRestaurants;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavLink('Beneficios', onBenefits),
        _NavLink('Como funciona', onHowItWorks),
        _NavLink('Restaurantes', onRestaurants),
        _NavLink('FAQ', onContact),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? LandingPalette.line.withAlpha(76) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: LandingType.bodyText(
              size: 14,
              color: _hovered ? LandingPalette.ink : LandingPalette.muted,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
