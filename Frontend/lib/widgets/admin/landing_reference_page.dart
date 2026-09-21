import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class _C {
  static const bg = Color(0xFFFAF5EC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF26201A);
  static const muted = Color(0xFF6F6259);
  static const line = Color(0xFFEAE1D3);
  static const accent = Color(0xFFBE4B24);
  static const accentDark = Color(0xFF9E3A18);
  static const accentSoft = Color(0xFFF8E7DC);
  static const olive = Color(0xFF55684B);
  static const oliveSoft = Color(0xFFE7EDDF);
  static const gold = Color(0xFFC08A2D);
  static const positive = Color(0xFF1F7A4D);
  static const positiveSoft = Color(0xFFE3F1E8);
  static const pending = Color(0xFF8A5A00);
  static const pendingSoft = Color(0xFFFBF0D9);
  static const purple = Color(0xFF4B4B8F);
  static const purpleSoft = Color(0xFFE8E8F5);
  static const ctaText = Color(0xFFFDF4EE);
  static const ctaEmphasis = Color(0xFFFCD9C4);
}

abstract final class _T {
  static TextStyle body({
    double size = 16,
    Color color = _C.muted,
    FontWeight weight = FontWeight.w400,
    double height = 1.6,
    double? spacing,
  }) => TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
  );

  static TextStyle display({
    double size = 44,
    Color color = _C.ink,
    FontWeight weight = FontWeight.w600,
    double height = 1.08,
    bool italic = false,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: -0.9,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );
}

const _shadowSmall = [
  BoxShadow(color: Color(0x0F26201A), blurRadius: 10, offset: Offset(0, 2)),
];
const _shadowMedium = [
  BoxShadow(color: Color(0x1A26201A), blurRadius: 34, offset: Offset(0, 12)),
];
const _shadowLarge = [
  BoxShadow(color: Color(0x2426201A), blurRadius: 60, offset: Offset(0, 24)),
];

class LandingReferencePage extends StatefulWidget {
  const LandingReferencePage({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<LandingReferencePage> createState() => _LandingReferencePageState();
}

class _LandingReferencePageState extends State<LandingReferencePage> {
  final _scrollController = ScrollController();
  final _benefitsKey = GlobalKey();
  final _panelKey = GlobalKey();
  final _profileKey = GlobalKey();
  final _restaurantsKey = GlobalKey();
  final _faqKey = GlobalKey();

  bool _scrolled = false;
  bool _menuOpen = false;
  bool _toastVisible = false;
  String _toastMessage = '';
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final next = _scrollController.offset > 12;
    if (next != _scrolled) setState(() => _scrolled = next);
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    setState(() => _menuOpen = false);
    Scrollable.ensureVisible(
      context,
      duration: MediaQuery.disableAnimationsOf(this.context)
          ? Duration.zero
          : const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      alignment: .02,
    );
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: DefaultTextStyle(
        style: _T.body(color: _C.ink),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _HeroSection(
                    onHowItWorks: () => _scrollTo(_panelKey),
                  ),
                  const _PhotoMarquee(),
                  _Anchor(key: _benefitsKey, child: const _BenefitsSection()),
                  _Anchor(key: _panelKey, child: const _PanelSection()),
                  const _StepsSection(),
                  _Anchor(key: _profileKey, child: const _ProfileSection()),
                  _Anchor(
                    key: _restaurantsKey,
                    child: const _TestimonialsSection(),
                  ),
                  _Anchor(key: _faqKey, child: const _FaqSection()),
                  _Footer(
                    onBenefits: () => _scrollTo(_benefitsKey),
                    onPanel: () => _scrollTo(_panelKey),
                    onProfile: () => _scrollTo(_profileKey),
                    onRestaurants: () => _scrollTo(_restaurantsKey),
                    onFaq: () => _scrollTo(_faqKey),
                    onToast: _showToast,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: _LandingNavbar(
                scrolled: _scrolled,
                menuOpen: _menuOpen,
                onMenuToggle: () => setState(() => _menuOpen = !_menuOpen),
                onBenefits: () => _scrollTo(_benefitsKey),
                onPanel: () => _scrollTo(_panelKey),
                onProfile: () => _scrollTo(_profileKey),
                onRestaurants: () => _scrollTo(_restaurantsKey),
                onFaq: () => _scrollTo(_faqKey),
                onLogin: widget.onLogin,
                onRegister: widget.onRegister,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 86,
              child: IgnorePointer(
                ignoring: !_menuOpen,
                child: AnimatedSlide(
                  offset: _menuOpen ? Offset.zero : const Offset(0, -.12),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _menuOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _MobileMenu(
                      onBenefits: () => _scrollTo(_benefitsKey),
                      onPanel: () => _scrollTo(_panelKey),
                      onProfile: () => _scrollTo(_profileKey),
                      onRestaurants: () => _scrollTo(_restaurantsKey),
                      onFaq: () => _scrollTo(_faqKey),
                      onLogin: widget.onLogin,
                      onRegister: widget.onRegister,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: IgnorePointer(
                ignoring: !_toastVisible,
                child: AnimatedSlide(
                  offset: _toastVisible ? Offset.zero : const Offset(0, 1.8),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _toastVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 360),
                    child: Center(child: _Toast(message: _toastMessage)),
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

class _Anchor extends StatelessWidget {
  const _Anchor({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _Wrap extends StatelessWidget {
  const _Wrap({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width <= 640 ? 20.0 : 24.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

class _LandingNavbar extends StatelessWidget {
  const _LandingNavbar({
    required this.scrolled,
    required this.menuOpen,
    required this.onMenuToggle,
    required this.onBenefits,
    required this.onPanel,
    required this.onProfile,
    required this.onRestaurants,
    required this.onFaq,
    required this.onLogin,
    required this.onRegister,
  });

  final bool scrolled;
  final bool menuOpen;
  final VoidCallback onMenuToggle;
  final VoidCallback onBenefits;
  final VoidCallback onPanel;
  final VoidCallback onProfile;
  final VoidCallback onRestaurants;
  final VoidCallback onFaq;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width <= 640;
    final compact = width <= 920;
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
                color: Colors.white.withValues(alpha: scrolled ? .95 : .82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _C.line.withValues(alpha: .9)),
                boxShadow: scrolled ? _shadowMedium : _shadowSmall,
              ),
              child: Row(
                children: [
                  const _Brand(compact: true),
                  if (!mobile) ...[
                    const Spacer(),
                    if (!compact)
                      _NavLinks(
                        onBenefits: onBenefits,
                        onPanel: onPanel,
                        onProfile: onProfile,
                        onRestaurants: onRestaurants,
                        onFaq: onFaq,
                      ),
                    const Spacer(),
                    if (!compact)
                      _TextButton(label: 'Iniciar sesión', onTap: onLogin),
                    const SizedBox(width: 4),
                    _PrimaryButton(
                      label: compact ? 'Registrar' : 'Registrar mi restaurante',
                      onTap: onRegister,
                      compact: compact,
                    ),
                  ] else ...[
                    const Spacer(),
                    _TextButton(label: 'Entrar', onTap: onLogin),
                    _PrimaryButton(
                      label: 'Registrar',
                      onTap: onRegister,
                      compact: true,
                    ),
                    const SizedBox(width: 2),
                    Semantics(
                      button: true,
                      label: menuOpen ? 'Cerrar menú' : 'Abrir menú',
                      child: IconButton(
                        onPressed: onMenuToggle,
                        icon: Icon(
                          menuOpen ? LucideIcons.x : LucideIcons.menu,
                          color: _C.ink,
                          size: 23,
                        ),
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
  }
}

class _NavLinks extends StatelessWidget {
  const _NavLinks({
    required this.onBenefits,
    required this.onPanel,
    required this.onProfile,
    required this.onRestaurants,
    required this.onFaq,
  });
  final VoidCallback onBenefits;
  final VoidCallback onPanel;
  final VoidCallback onProfile;
  final VoidCallback onRestaurants;
  final VoidCallback onFaq;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _NavLink('Beneficios', onBenefits),
      _NavLink('Cómo funciona', onPanel),
      _NavLink('Tu perfil', onProfile),
      _NavLink('Restaurantes', onRestaurants),
      _NavLink('FAQ', onFaq),
    ],
  );
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Semantics(
      button: true,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? _C.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: _T.body(
              size: 14,
              color: _hovered ? _C.ink : _C.muted,
              weight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
    required this.onBenefits,
    required this.onPanel,
    required this.onProfile,
    required this.onRestaurants,
    required this.onFaq,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onBenefits;
  final VoidCallback onPanel;
  final VoidCallback onProfile;
  final VoidCallback onRestaurants;
  final VoidCallback onFaq;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.line),
        boxShadow: _shadowLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MobileLink('Beneficios', onBenefits),
          _MobileLink('Cómo funciona', onPanel),
          _MobileLink('Tu perfil', onProfile),
          _MobileLink('Restaurantes', onRestaurants),
          _MobileLink('FAQ', onFaq),
          _MobileLink('Iniciar sesión', onLogin),
          _MobileLink(
            'Registrar mi restaurante →',
            onRegister,
            color: _C.accent,
          ),
        ],
      ),
    ),
  );
}

class _MobileLink extends StatelessWidget {
  const _MobileLink(this.label, this.onTap, {this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: color ?? _C.muted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _T.body(weight: FontWeight.w600, height: 1.2),
      ),
      child: Text(label),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          'assets/icon_app.webp',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'Mesa Chapaca',
        style: _T.display(
          size: compact ? 19 : 20,
          weight: FontWeight.w600,
          height: 1,
        ),
      ),
    ],
  );
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onHowItWorks});
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width <= 1020;
    final mobile = width <= 640;
    return Padding(
      padding: EdgeInsets.only(
        top: tablet ? 150 : 170,
        bottom: tablet ? 60 : 80,
      ),
      child: _Wrap(
        child: tablet
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCopy(
                    mobile: mobile,
                    onHowItWorks: onHowItWorks,
                  ),
                  const SizedBox(height: 44),
                  const Center(child: _HeroArt()),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 105,
                    child: _HeroCopy(
                      mobile: false,
                      onHowItWorks: onHowItWorks,
                    ),
                  ),
                  const SizedBox(width: 60),
                  const Expanded(flex: 95, child: _HeroArt()),
                ],
              ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.mobile,
    required this.onHowItWorks,
  });
  final bool mobile;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) => _Reveal(
    initiallyVisible: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LiveChip(),
        const SizedBox(height: 22),
        _AccentTitle(
          before: 'Tu restaurante merece una ',
          accent: 'mesa llena.',
          size: mobile ? 43 : 68,
          maxWidth: 650,
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Text(
            'Publica tu perfil, recibe reservas en tiempo real y coordina todo tu salón desde un solo lugar. Sin permanencia, sin letra pequeña.',
            style: _T.body(size: 18, height: 1.58),
          ),
        ),
        const SizedBox(height: 30),
        _OutlineButton(label: 'Ver cómo funciona', onTap: onHowItWorks),
        const SizedBox(height: 34),
        _HeroStats(mobile: mobile),
      ],
    ),
  );
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _C.line),
      boxShadow: _shadowSmall,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PingDot(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Recibiendo restaurantes nuevos esta semana',
            style: _T.body(size: 13.5, weight: FontWeight.w600, height: 1.2),
          ),
        ),
      ],
    ),
  );
}

class _PingDot extends StatefulWidget {
  const _PingDot();

  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF2E8B5F),
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 8, height: 8),
          ),
        ),
      );
    }
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: .6 + (_controller.value * .9),
              child: Opacity(
                opacity: math.max(0, .5 * (1 - _controller.value)),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF2E8B5F),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 15, height: 15),
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF2E8B5F),
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 8, height: 8),
          ),
        ],
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _Stat(count: 120, suffix: '+', label: 'restaurantes activos'),
      const _Stat(count: 38, suffix: ' mil', label: 'reservas gestionadas'),
      const _Stat(text: '4.9 ', accentText: '★', label: 'valoración media'),
    ];
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.only(top: 26),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.line)),
      ),
      child: mobile
          ? Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  SizedBox(width: double.infinity, child: items[i]),
                  if (i != items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1, color: _C.line),
                    ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i != items.length - 1)
                    const SizedBox(
                      height: 58,
                      child: VerticalDivider(width: 26, color: _C.line),
                    ),
                ],
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    this.count,
    this.suffix = '',
    this.text,
    this.accentText,
    required this.label,
  });
  final int? count;
  final String suffix;
  final String? text;
  final String? accentText;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (count != null)
        TweenAnimationBuilder<double>(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 1300),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: count!.toDouble()),
          builder: (context, value, child) => Text(
            '${value.round()}$suffix',
            style: _T.display(size: 30, weight: FontWeight.w600, height: 1.15),
          ),
        )
      else
        RichText(
          text: TextSpan(
            style: _T.display(size: 30, weight: FontWeight.w600, height: 1.15),
            children: [
              TextSpan(text: text),
              TextSpan(
                text: accentText,
                style: const TextStyle(color: _C.accent),
              ),
            ],
          ),
        ),
      const SizedBox(height: 3),
      Text(
        label,
        style: _T.body(size: 13, weight: FontWeight.w500, height: 1.3),
      ),
    ],
  );
}

class _HeroArt extends StatefulWidget {
  const _HeroArt();

  @override
  State<_HeroArt> createState() => _HeroArtState();
}

class _HeroArtState extends State<_HeroArt> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 640;
    return _Reveal(
      initiallyVisible: true,
      delay: const Duration(milliseconds: 150),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AspectRatio(
          aspectRatio: mobile ? .78 : .86,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() => _hovered = false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: _shadowLarge,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedScale(
                      scale: _hovered ? 1.09 : 1.02,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(seconds: 6),
                      curve: Curves.ease,
                      child: Image.asset(
                        'assets/landing_reference/hero.webp',
                        fit: BoxFit.cover,
                        semanticLabel: 'Interior de restaurante cálido',
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: _C.accent),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 26,
                right: mobile ? -4 : -30,
                child: const _FloatingCard(
                  delay: .3,
                  child: _ReservationFloatCard(),
                ),
              ),
              Positioned(
                bottom: mobile ? -16 : -24,
                right: mobile ? 2 : 14,
                child: const _FloatingCard(
                  delay: 1.1,
                  child: _TodayFloatCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCard extends StatefulWidget {
  const _FloatingCard({required this.child, required this.delay});
  final Widget child;
  final double delay;

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
      value: widget.delay / 5,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.line),
          boxShadow: _shadowMedium,
        ),
        child: widget.child,
      ),
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          still ? 0 : -10 * Curves.easeInOut.transform(_controller.value),
        ),
        child: child,
      ),
    );
  }
}

class _ReservationFloatCard extends StatelessWidget {
  const _ReservationFloatCard();

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 640;
    return SizedBox(
      width: mobile ? 210 : 238,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: LucideIcons.badgeCheck,
                foreground: _C.positive,
                background: _C.positiveSoft,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva confirmada',
                      style: _T.body(
                        size: 13.5,
                        color: _C.ink,
                        weight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mesa 4 · 19:30 · 2 personas',
                      style: _T.body(size: 11.5, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _StatusPill('Mesa lista', positive: true),
              _StatusPill('Cocina avisada'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayFloatCard extends StatelessWidget {
  const _TodayFloatCard();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESERVAS DE HOY',
          style: _T.body(
            size: 11,
            weight: FontWeight.w700,
            spacing: 1,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '26',
              style: _T.display(size: 32, weight: FontWeight.w600, height: 1),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trendingUp, size: 14, color: _C.positive),
                  SizedBox(width: 3),
                  Text(
                    '+18%',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      color: _C.positive,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const CustomPaint(size: Size(120, 30), painter: _SparkPainter()),
      ],
    ),
  );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    const points = [
      Offset(4, 24),
      Offset(22, 20),
      Offset(40, 22),
      Offset(58, 13),
      Offset(76, 15),
      Offset(94, 7),
      Offset(116, 4),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _C.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => false;
}

class _PhotoMarquee extends StatefulWidget {
  const _PhotoMarquee();

  @override
  State<_PhotoMarquee> createState() => _PhotoMarqueeState();
}

class _PhotoMarqueeState extends State<_PhotoMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const _widths = [
    250.0,
    278.0,
    230.0,
    286.0,
    260.0,
    218.0,
    270.0,
    242.0,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 44),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final cycleWidth = _widths.fold<double>(0, (a, b) => a + b) + (16 * 8);
    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 10),
      child: Column(
        children: [
          const _Reveal(
            child: _Chip(text: 'La mesa que hoy está vacía, mañana está llena'),
          ),
          const SizedBox(height: 26),
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0, .08, .92, 1],
            ).createShader(rect),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: ClipRect(
                child: MouseRegion(
                  onEnter: (_) {
                    _controller.stop();
                  },
                  onExit: (_) {
                    if (!reduced) _controller.repeat();
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        reduced ? 0 : -cycleWidth * _controller.value,
                        0,
                      ),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var repeat = 0; repeat < 2; repeat++)
                              for (var i = 0; i < 8; i++) ...[
                                _MarqueeImage(index: i + 1, width: _widths[i]),
                                const SizedBox(width: 16),
                              ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeImage extends StatefulWidget {
  const _MarqueeImage({required this.index, required this.width});
  final int index;
  final double width;

  @override
  State<_MarqueeImage> createState() => _MarqueeImageState();
}

class _MarqueeImageState extends State<_MarqueeImage> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedOpacity(
      opacity: _hovered ? .92 : 1,
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/landing_reference/marquee_${widget.index.toString().padLeft(2, '0')}.webp',
          width: widget.width,
          height: 190,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => SizedBox(
            width: widget.width,
            height: 190,
            child: const ColoredBox(color: _C.line),
          ),
        ),
      ),
    ),
  );
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  static const _items = [
    _BenefitData(
      LucideIcons.eye,
      _C.accent,
      _C.accentSoft,
      'más visible',
      'Perfil que enamora',
      'Platos, ambiente y horarios presentados como se merecen. La mejor vitrina de tu cocina, sin diseñador.',
    ),
    _BenefitData(
      LucideIcons.listChecks,
      _C.olive,
      _C.oliveSoft,
      'más orden',
      'Reservas en tiempo real',
      'Cada reserva llega confirmada y notificada a tu equipo. Se acabó el cuaderno y las llamadas cruzadas.',
    ),
    _BenefitData(
      LucideIcons.chefHat,
      _C.gold,
      Color(0xFFFBEFD9),
      'más sabor',
      'Menú siempre al día',
      'Actualiza platos, precios y disponibilidad en segundos. El cliente siempre ve lo que hoy sale de tu cocina.',
    ),
    _BenefitData(
      LucideIcons.messagesSquare,
      _C.purple,
      _C.purpleSoft,
      'más voces',
      'Reseñas que suman',
      'Responde a tus comensales y construye reputación. Las buenas experiencias se vuelven tu mejor publicidad.',
    ),
    _BenefitData(
      LucideIcons.clock,
      _C.olive,
      _C.oliveSoft,
      'más tiempo',
      'Menos coordinación',
      'Salón, cocina y recepción en la misma página, literalmente. Tu equipo trabaja informado desde la mañana.',
    ),
    _BenefitData(
      LucideIcons.lifeBuoy,
      _C.accent,
      _C.accentSoft,
      'más calma',
      'Soporte humano',
      'Personas reales que conocen la operación de un restaurante y te acompañan desde el día uno.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width <= 640 ? 1 : (width <= 1020 ? 2 : 3);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            kicker: 'Beneficios',
            before: 'Todo lo que tu salón necesita, ',
            accent: 'sin complicarte.',
            subtitle:
                'Herramientas pensadas para la operación real de un restaurante: simples, rápidas y siempre a la mano.',
          ),
          _ResponsiveGrid(
            columns: columns,
            gap: 20,
            children: [
              for (var i = 0; i < _items.length; i++)
                _Reveal(
                  delay: Duration(milliseconds: (i % columns) * 80),
                  child: _HoverLift(child: _BenefitCard(data: _items[i])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitData {
  const _BenefitData(
    this.icon,
    this.color,
    this.background,
    this.tagline,
    this.title,
    this.body,
  );
  final IconData icon;
  final Color color;
  final Color background;
  final String tagline;
  final String title;
  final String body;
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.data});
  final _BenefitData data;

  @override
  Widget build(BuildContext context) => Container(
    height: 255,
    padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _C.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconTile(
              icon: data.icon,
              foreground: data.color,
              background: data.background,
              size: 50,
            ),
            const Spacer(),
            Text(
              data.tagline,
              style: _T.display(
                size: 14,
                color: _C.accent,
                italic: true,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          data.title,
          style: _T.body(
            size: 18,
            color: _C.ink,
            weight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Text(data.body, style: _T.body(size: 14.5, height: 1.52)),
        ),
      ],
    ),
  );
}

class _PanelSection extends StatelessWidget {
  const _PanelSection();

  @override
  Widget build(BuildContext context) {
    final oneColumn = MediaQuery.sizeOf(context).width <= 1020;
    final copy = _Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('El panel'),
          const SizedBox(height: 16),
          const _AccentTitle(
            before: 'Todo tu salón en ',
            accent: 'una sola vista.',
            size: 46,
            maxWidth: 450,
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Abre tu día sabiendo exactamente quién viene, a qué hora y con cuántos. Así se siente tener el control.',
              style: _T.body(size: 17),
            ),
          ),
          const SizedBox(height: 28),
          const _Checks(
            items: [
              'Reservas del día, confirmadas y pendientes, en una pantalla',
              'Reservas actualizadas para cocina y personal de sala',
              'Ocupación y tiempos de espera siempre visibles',
              'Funciona en el celular, la tablet o la compu de la caja',
            ],
          ),
        ],
      ),
    );
    const panel = _Reveal(
      delay: Duration(milliseconds: 120),
      child: _ReservationDashboard(),
    );
    final content = oneColumn
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 44), panel],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 9, child: copy),
              const SizedBox(width: 64),
              const Expanded(flex: 11, child: panel),
            ],
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border.symmetric(horizontal: BorderSide(color: _C.line)),
      ),
      child: _Section(child: content),
    );
  }
}

class _ReservationDashboard extends StatelessWidget {
  const _ReservationDashboard();
  static const _rows = [
    _ReservationData(
      '12:30',
      'Familia Rojas',
      'Mesa 2 · Terraza',
      '6 pers.',
      'Mesa lista',
      true,
    ),
    _ReservationData(
      '13:00',
      'Andrea Silva',
      'Mesa 4 · Sala principal',
      '2 pers.',
      'Confirmada',
      true,
    ),
    _ReservationData(
      '13:15',
      'Jorge Paz',
      'Mesa 7 · Ventana',
      '4 pers.',
      'Por confirmar',
      false,
    ),
    _ReservationData(
      '20:00',
      'Aniversario Vargas',
      'Mesa 1 · Decorada',
      '8 pers.',
      'Mesa lista',
      true,
    ),
    _ReservationData(
      '21:30',
      'Cena Serrano',
      'Mesa 5 · Sala principal',
      '2 pers.',
      'Confirmada',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 640;
    return Container(
      padding: mobile ? const EdgeInsets.all(14) : const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _C.line),
        boxShadow: _shadowLarge,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(
                icon: LucideIcons.calendarCheck,
                foreground: Colors.white,
                background: _C.accent,
                size: 34,
                radius: 10,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Salón · Reservas',
                  style: _T.body(
                    size: 16,
                    color: _C.ink,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _C.line),
                ),
                child: Text(
                  'Hoy, 20 de junio',
                  style: _T.body(
                    size: mobile ? 10.5 : 12,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (_, box) {
              final twoColumns = mobile;
              final cards = const [
                _Kpi('RESERVAS', '26'),
                _Kpi('OCUPACIÓN', '84%', positive: true),
                _Kpi('LISTA', '2'),
              ];
              return _ResponsiveGrid(
                columns: twoColumns ? 2 : 3,
                gap: 10,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),
          _StaggeredRows(rows: _rows),
        ],
      ),
    );
  }
}

class _ReservationData {
  const _ReservationData(
    this.time,
    this.name,
    this.table,
    this.guests,
    this.status,
    this.positive,
  );
  final String time;
  final String name;
  final String table;
  final String guests;
  final String status;
  final bool positive;
}

class _StaggeredRows extends StatefulWidget {
  const _StaggeredRows({required this.rows});
  final List<_ReservationData> rows;

  @override
  State<_StaggeredRows> createState() => _StaggeredRowsState();
}

class _StaggeredRowsState extends State<_StaggeredRows> {
  final _visible = <int>{};
  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (_position != next) {
      _position?.removeListener(_check);
      _position = next?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _started) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * .84) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(
          () => _visible.addAll(List.generate(widget.rows.length, (i) => i)),
        );
        return;
      }
      for (var i = 0; i < widget.rows.length; i++) {
        Timer(Duration(milliseconds: i * 160), () {
          if (mounted) setState(() => _visible.add(i));
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < widget.rows.length; i++) ...[
        AnimatedSlide(
          offset: _visible.contains(i) ? Offset.zero : const Offset(.04, 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _visible.contains(i) ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: _ReservationRow(data: widget.rows[i]),
          ),
        ),
        if (i != widget.rows.length - 1) const SizedBox(height: 8),
      ],
    ],
  );
}

class _ReservationRow extends StatefulWidget {
  const _ReservationRow({required this.data});
  final _ReservationData data;

  @override
  State<_ReservationRow> createState() => _ReservationRowState();
}

class _ReservationRowState extends State<_ReservationRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 640;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 10 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hovered ? _C.accent : _C.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: mobile ? 48 : 58,
              child: Text(
                widget.data.time,
                style: _T.display(
                  size: mobile ? 14 : 16,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.body(
                      size: mobile ? 12 : 13.5,
                      color: _C.ink,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.data.table,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.body(size: mobile ? 10.5 : 11.5, height: 1.2),
                  ),
                ],
              ),
            ),
            if (!mobile) ...[
              const SizedBox(width: 10),
              Text(
                widget.data.guests,
                style: _T.body(size: 12, weight: FontWeight.w600, height: 1.2),
              ),
            ],
            const SizedBox(width: 10),
            _StatusPill(widget.data.status, positive: widget.data.positive),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, {this.positive = false});
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _T.body(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: .6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: _T.display(
            size: 23,
            color: positive ? _C.positive : _C.ink,
            weight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

class _StepsSection extends StatelessWidget {
  const _StepsSection();
  static const _steps = [
    _StepData(
      '01',
      'Envía tu solicitud',
      'Cuéntanos de tu restaurante: nombre, tipo de cocina y horario. Nada de formularios eternos.',
      LucideIcons.zap,
      'Respuesta en menos de 24 h',
    ),
    _StepData(
      '02',
      'Prepara tu espacio',
      'Cargamos tu menú, fotos y mesas contigo. Te acompañamos en el setup con soporte inicial personalizado.',
      LucideIcons.sparkles,
      'Setup guiado',
    ),
    _StepData(
      '03',
      'Recibe reservas',
      'Las reservas llegan confirmadas, en tiempo real, y tu equipo queda coordinado desde el primer día.',
      LucideIcons.bell,
      'Actualización en vivo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width <= 640 ? 1 : (width <= 1020 ? 2 : 3);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            kicker: 'Cómo funciona',
            before: 'De la solicitud a tu primera reserva, ',
            accent: 'en tres pasos.',
          ),
          _ResponsiveGrid(
            columns: columns,
            gap: 22,
            children: [
              for (var i = 0; i < _steps.length; i++)
                _Reveal(
                  delay: Duration(milliseconds: i * 100),
                  child: _HoverLift(child: _StepCard(data: _steps[i])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData(this.number, this.title, this.body, this.icon, this.pill);
  final String number;
  final String title;
  final String body;
  final IconData icon;
  final String pill;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data});
  final _StepData data;

  @override
  Widget build(BuildContext context) => Container(
    height: 310,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _C.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OutlinedNumber(data.number),
        const SizedBox(height: 18),
        Text(
          data.title,
          style: _T.body(
            size: 18,
            color: _C.ink,
            weight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Text(data.body, style: _T.body(size: 14.5, height: 1.5)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _C.oliveSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, color: _C.olive, size: 14),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  data.pill,
                  style: _T.body(
                    size: 12,
                    color: _C.olive,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OutlinedNumber extends StatelessWidget {
  const _OutlinedNumber(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Text(
        text,
        style: _T.display(
          size: 54,
          color: _C.accentSoft,
          weight: FontWeight.w600,
          height: 1,
        ),
      ),
      Positioned.fill(
        child: Text(
          text,
          style: _T
              .display(
                size: 54,
                color: _C.accentSoft,
                weight: FontWeight.w600,
                height: 1,
              )
              .copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.5
                  ..color = _C.accent,
              ),
        ),
      ),
    ],
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) => _Section(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          kicker: 'Tu perfil',
          before: 'Un perfil que se siente ',
          accent: 'como tu restaurante.',
          subtitle:
              'No somos un directorio genérico. Tu propuesta, tu ambiente y tu operación, tal como son.',
        ),
        const _ProfileRow(
          image: 'assets/landing_reference/marquee_05.webp',
          imageLabel: 'Plato principal',
          kicker: 'Tu propuesta',
          before: 'Haz visible lo que te hace ',
          accent: 'especial.',
          body:
              'Fotos que abren el apetito, descripciones con alma y precios claros. Tu cocina presentada como en tu mejor noche.',
          checks: [
            'Galería de platos con etiquetas y destacados',
            'Menú editable en segundos, cuando tú quieras',
          ],
          badgeIcon: LucideIcons.flame,
          badgeColor: _C.accent,
          badgeBackground: _C.accentSoft,
          badge: 'Plato estrella: Churrasco Chapaco',
        ),
        SizedBox(height: 90),
        const _ProfileRow(
          image: 'assets/landing_reference/profile_02.webp',
          imageLabel: 'Mesa puesta en terraza',
          kicker: 'Tu ambiente',
          before: 'Convierte una visita en ',
          accent: 'una experiencia.',
          body:
              'Mesas junto a la ventana, terraza al atardecer, rincón romántico. El comensal elige su lugar antes de llegar, y llega queriendo volver.',
          checks: [
            'Zonas y ambientes con fotos propias',
            'Reservas por mesa, no solo por persona',
          ],
          badgeIcon: LucideIcons.lamp,
          badgeColor: _C.olive,
          badgeBackground: _C.oliveSoft,
          badge: 'Terraza · Disponible desde 12:00',
          reversed: true,
        ),
        SizedBox(height: 90),
        const _ProfileRow(
          image: 'assets/landing_reference/marquee_08.webp',
          imageLabel: 'Copas de vino en mesa',
          kicker: 'Tu operación',
          before: 'Coordina cada servicio ',
          accent: 'con claridad.',
          body:
              'Solicitudes especiales, aniversarios, alergias: todo llega anotado en la reserva para que tu equipo no improvise nunca más.',
          checks: [
            'Notas del comensal visibles para sala y cocina',
            'Estados de mesa compartidos con todo el equipo',
          ],
          badgeIcon: LucideIcons.wine,
          badgeColor: _C.gold,
          badgeBackground: Color(0xFFFBEFD9),
          badge: 'Maridaje sugerido por el chef',
        ),
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.image,
    required this.imageLabel,
    required this.kicker,
    required this.before,
    required this.accent,
    required this.body,
    required this.checks,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeBackground,
    required this.badge,
    this.reversed = false,
  });
  final String image;
  final String imageLabel;
  final String kicker;
  final String before;
  final String accent;
  final String body;
  final List<String> checks;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeBackground;
  final String badge;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final oneColumn = MediaQuery.sizeOf(context).width <= 1020;
    final media = _ProfileMedia(
      image: image,
      imageLabel: imageLabel,
      badgeIcon: badgeIcon,
      badgeColor: badgeColor,
      badgeBackground: badgeBackground,
      badge: badge,
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Kicker(kicker),
        const SizedBox(height: 14),
        _AccentTitle(before: before, accent: accent, size: 36, maxWidth: 500),
        const SizedBox(height: 14),
        Text(body, style: _T.body(size: 16)),
        const SizedBox(height: 22),
        _Checks(items: checks),
      ],
    );
    final children = oneColumn || !reversed
        ? [
            Expanded(child: media),
            const SizedBox(width: 64),
            Expanded(child: copy),
          ]
        : [
            Expanded(child: copy),
            const SizedBox(width: 64),
            Expanded(child: media),
          ];
    return _Reveal(
      child: oneColumn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [media, const SizedBox(height: 36), copy],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
    );
  }
}

class _ProfileMedia extends StatefulWidget {
  const _ProfileMedia({
    required this.image,
    required this.imageLabel,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeBackground,
    required this.badge,
  });
  final String image;
  final String imageLabel;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeBackground;
  final String badge;

  @override
  State<_ProfileMedia> createState() => _ProfileMediaState();
}

class _ProfileMediaState extends State<_ProfileMedia> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AspectRatio(
            aspectRatio: 4 / 3.1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: _shadowLarge,
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedScale(
                scale: _hovered ? 1.07 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(seconds: 5),
                curve: Curves.ease,
                child: Image.asset(
                  widget.image,
                  fit: BoxFit.cover,
                  semanticLabel: widget.imageLabel,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: _C.line),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          bottom: -18,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: math.min(330, MediaQuery.sizeOf(context).width - 88),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.line),
              boxShadow: _shadowMedium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconTile(
                  icon: widget.badgeIcon,
                  foreground: widget.badgeColor,
                  background: widget.badgeBackground,
                  size: 34,
                  radius: 10,
                  iconSize: 16,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.badge,
                    style: _T.body(
                      size: 13.5,
                      color: _C.ink,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();
  static const _items = [
    _TestimonialData(
      'Las reservas llegan ordenadas y mi equipo ya sabe desde la mañana cómo preparar la sala. Cambió nuestra rutina por completo.',
      'CM',
      'Carlos Montaño',
      'La Casona Tarijena',
      _C.accent,
    ),
    _TestimonialData(
      'Actualizar el menú toma dos minutos. Antes los clientes pedían platos que ya no servíamos; ahora eso simplemente no pasa.',
      'MF',
      'María Flores',
      'El Viñedo del Sur',
      _C.olive,
    ),
    _TestimonialData(
      'Podemos responder las reseñas y agradecer a quienes nos visitan. La gente vuelve, y llega recomendando el lugar a otros.',
      'RV',
      'Roberto Vega',
      'Rincón Criollo',
      _C.gold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width <= 640 ? 1 : (width <= 1020 ? 2 : 3);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border.symmetric(horizontal: BorderSide(color: _C.line)),
      ),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              kicker: 'Restaurantes que avanzan',
              before: 'Más tiempo para recibir. ',
              accent: 'Menos tiempo coordinando.',
            ),
            _ResponsiveGrid(
              columns: columns,
              gap: 22,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _Reveal(
                    delay: Duration(milliseconds: i * 100),
                    child: _HoverLift(child: _TestimonialCard(data: _items[i])),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialData {
  const _TestimonialData(
    this.quote,
    this.initials,
    this.name,
    this.restaurant,
    this.color,
  );
  final String quote;
  final String initials;
  final String name;
  final String restaurant;
  final Color color;
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.data});
  final _TestimonialData data;

  @override
  Widget build(BuildContext context) => Container(
    height: 340,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: _C.bg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _C.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.star, color: _C.gold, size: 17),
            Icon(LucideIcons.star, color: _C.gold, size: 17),
            Icon(LucideIcons.star, color: _C.gold, size: 17),
            Icon(LucideIcons.star, color: _C.gold, size: 17),
            Icon(LucideIcons.star, color: _C.gold, size: 17),
          ],
        ),
        Text('“', style: _T.display(size: 58, color: _C.accent, height: .8)),
        const SizedBox(height: 4),
        Expanded(
          child: Text(
            data.quote,
            style: _T.body(
              size: 15,
              color: _C.ink,
              weight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: data.color,
              child: Text(
                data.initials,
                style: _T.body(
                  size: 14,
                  color: Colors.white,
                  weight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: _T.body(
                      size: 14,
                      color: _C.ink,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.restaurant,
                    style: _T.body(size: 12.5, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FaqSection extends StatefulWidget {
  const _FaqSection();

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  int? _open;
  static const _items = [
    (
      '¿Cuánto cuesta publicar mi restaurante?',
      'El alta y el setup inicial no tienen costo. Luego de tu primer mes de reservas, eliges el plan que mejor se ajuste a tu operación, sin permanencia.',
    ),
    (
      '¿Necesito computadoras o equipos especiales?',
      'No. Todo funciona desde el navegador de tu celular o tablet. Si ya tienes una compu en la caja, también funciona perfectamente ahí.',
    ),
    (
      '¿Qué pasa con las reservas por teléfono?',
      'Conviven. Puedes registrar manualmente cualquier reserva hecha por llamada o walk-in, y queda reflejada en el mismo tablero que las online.',
    ),
    (
      '¿Cuánto tarda la revisión de mi solicitud?',
      'Menos de 24 horas hábiles. Revisamos que la información esté completa y te contactamos para coordinar el setup de tu perfil juntos.',
    ),
    (
      '¿Puedo editar el menú y las fotos cuando quiera?',
      'Sí, siempre. Menú, precios, fotos, horarios y zonas: todo se actualiza al instante, sin pedir permiso a nadie.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _Section(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            const _SectionHeader(
              kicker: 'Dudas frecuentes',
              before: 'Lo que nos preguntan ',
              accent: 'antes de empezar.',
              centered: true,
            ),
            for (var i = 0; i < _items.length; i++)
              _Reveal(
                child: _FaqItem(
                  question: _items[i].$1,
                  answer: _items[i].$2,
                  open: _open == i,
                  onTap: () => setState(() => _open = _open == i ? null : i),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.open,
    required this.onTap,
  });
  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _C.line)),
    ),
    child: Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: _T.body(
                        size: 16.5,
                        color: _hovered && !widget.open ? _C.accent : _C.ink,
                        weight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.open ? _C.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.open ? _C.accent : _C.line,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedRotation(
                      turns: widget.open ? .5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: widget.open ? Colors.white : _C.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
          alignment: Alignment.topCenter,
          child: widget.open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 48, 24),
                  child: Text(
                    widget.answer,
                    style: _T.body(size: 15.5, height: 1.55),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
}

class _AccessSection extends StatefulWidget {
  const _AccessSection({required this.onToast});
  final ValueChanged<String> onToast;

  @override
  State<_AccessSection> createState() => _AccessSectionState();
}

class _AccessSectionState extends State<_AccessSection> {
  final _email = TextEditingController();
  final _focus = FocusNode();

  void _submit() {
    if (!_email.text.contains('@')) {
      widget.onToast('Revisa tu correo: parece incompleto.');
      _focus.requestFocus();
      return;
    }
    widget.onToast('¡Solicitud enviada! Te contactamos en menos de 24 horas.');
    _email.clear();
    _focus.unfocus();
  }

  @override
  void dispose() {
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 640;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 110),
      child: _Wrap(
        child: _Reveal(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 32 : 64,
              vertical: mobile ? 52 : 72,
            ),
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(mobile ? 26 : 32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59BE4B24),
                  blurRadius: 70,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned(
                  right: -100,
                  top: -140,
                  child: _OutlineCircle(size: 340),
                ),
                const Positioned(
                  left: 30,
                  bottom: -130,
                  child: _OutlineCircle(size: 220),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AccentTitle(
                        before: 'Tu mesa llena empieza ',
                        accent: 'con una solicitud.',
                        size: 48,
                        maxWidth: 580,
                        color: _C.ctaText,
                        accentColor: _C.ctaEmphasis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Déjanos tu correo y te contactamos en menos de 24 horas para preparar el perfil de tu restaurante.',
                        style: _T.body(
                          size: 17,
                          color: _C.ctaText.withValues(alpha: .92),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (mobile)
                        Column(
                          children: [
                            _EmailField(
                              controller: _email,
                              focusNode: _focus,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _CreamButton(onTap: _submit),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _EmailField(
                                controller: _email,
                                focusNode: _focus,
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _CreamButton(onTap: _submit),
                          ],
                        ),
                      const SizedBox(height: 18),
                      const Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          _CtaNote(LucideIcons.shieldCheck, 'Sin permanencia'),
                          _CtaNote(
                            LucideIcons.headset,
                            'Setup guiado por personas',
                          ),
                          _CtaNote(
                            LucideIcons.lock,
                            'Tus datos siempre son tuyos',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  const _OutlineCircle({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _C.ctaText.withValues(alpha: .22), width: 2),
    ),
  );
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.done,
    onSubmitted: onSubmitted,
    style: _T.body(size: 15, color: _C.ink, height: 1.2),
    decoration: InputDecoration(
      hintText: 'correo@turestaurante.com',
      hintStyle: _T.body(size: 15, height: 1.2),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0x66FFFFFF), width: 4),
      ),
    ),
  );
}

class _CreamButton extends StatelessWidget {
  const _CreamButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onTap,
    iconAlignment: IconAlignment.end,
    icon: const Icon(LucideIcons.arrowRight, size: 17),
    label: const Text('Solicitar acceso'),
    style: FilledButton.styleFrom(
      minimumSize: const Size(190, 56),
      backgroundColor: _C.bg,
      foregroundColor: _C.accentDark,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      textStyle: _T.body(
        size: 15,
        color: _C.accentDark,
        weight: FontWeight.w600,
        height: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      elevation: 0,
    ),
  );
}

class _CtaNote extends StatelessWidget {
  const _CtaNote(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _C.ctaText.withValues(alpha: .9)),
      const SizedBox(width: 7),
      Text(
        text,
        style: _T.body(
          size: 13,
          color: _C.ctaText.withValues(alpha: .9),
          weight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onBenefits,
    required this.onPanel,
    required this.onProfile,
    required this.onRestaurants,
    required this.onFaq,
    required this.onToast,
  });
  final VoidCallback onBenefits;
  final VoidCallback onPanel;
  final VoidCallback onProfile;
  final VoidCallback onRestaurants;
  final VoidCallback onFaq;
  final ValueChanged<String> onToast;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width <= 640 ? 1 : (width <= 1020 ? 2 : 4);
    final parts = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(),
          const SizedBox(height: 14),
          Text(
            'La plataforma que llena mesas y ordena salones. Hecha con cariño en Tarija, Bolivia, para los restaurantes de todo el país.',
            style: _T.body(size: 14.5, height: 1.55),
          ),
        ],
      ),
      _FooterColumn(
        title: 'Producto',
        links: [
          ('Beneficios', onBenefits),
          ('Cómo funciona', onPanel),
          ('Tu perfil', onProfile),
          ('Preguntas', onFaq),
        ],
      ),
      _FooterColumn(
        title: 'Restaurantes',
        links: [
          ('Historias', onRestaurants),
        ],
      ),
      _FooterColumn(
        title: 'Contacto',
        links: [
          (
            'hola@mesachapaca.bo',
            () => onToast('Escríbenos a hola@mesachapaca.bo'),
          ),
          ('+591 700 00000', () => onToast('Llámanos al +591 700 00000')),
          ('Tarija, Bolivia', () => onToast('Estamos en Tarija, Bolivia')),
        ],
      ),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 56, bottom: 34),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.line)),
      ),
      child: _Wrap(
        child: Column(
          children: [
            _ResponsiveGrid(columns: columns, gap: 40, children: parts),
            const SizedBox(height: 44),
            const Divider(height: 1, color: _C.line),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (_, box) => box.maxWidth < 560
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '© 2025 Mesa Chapaca. Todos los derechos reservados.',
                          style: _T.body(size: 13),
                        ),
                        const SizedBox(height: 8),
                        Text('Términos · Privacidad', style: _T.body(size: 13)),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          '© 2025 Mesa Chapaca. Todos los derechos reservados.',
                          style: _T.body(size: 13),
                        ),
                        const Spacer(),
                        Text('Términos · Privacidad', style: _T.body(size: 13)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});
  final String title;
  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: _T.body(
          size: 12,
          weight: FontWeight.w700,
          spacing: 1.2,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 12),
      for (final link in links)
        TextButton(
          onPressed: link.$2,
          style: TextButton.styleFrom(
            foregroundColor: _C.ink,
            padding: const EdgeInsets.symmetric(vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: _T.body(
              size: 14.5,
              color: _C.ink,
              weight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          child: Text(link.$1),
        ),
    ],
  );
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 560),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: _C.ink,
      borderRadius: BorderRadius.circular(999),
      boxShadow: _shadowLarge,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF87),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 11),
        Flexible(
          child: Text(
            message,
            style: _T.body(
              size: 14,
              color: const Color(0xFFFDF8F1),
              weight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width <= 640 ? 70 : 96),
      child: _Wrap(child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.kicker,
    required this.before,
    required this.accent,
    this.subtitle,
    this.centered = false,
  });
  final String kicker;
  final String before;
  final String accent;
  final String? subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) => _Reveal(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 52),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          _Kicker(kicker),
          const SizedBox(height: 16),
          _AccentTitle(
            before: before,
            accent: accent,
            size: 46,
            maxWidth: 720,
            textAlign: centered ? TextAlign.center : TextAlign.left,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 610),
              child: Text(
                subtitle!,
                textAlign: centered ? TextAlign.center : TextAlign.left,
                style: _T.body(size: 16.5),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26,
        height: 2,
        decoration: BoxDecoration(
          color: _C.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: _T.body(
          size: 12,
          color: _C.accent,
          weight: FontWeight.w700,
          spacing: 1.65,
          height: 1.2,
        ),
      ),
    ],
  );
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle({
    required this.before,
    required this.accent,
    required this.size,
    required this.maxWidth,
    this.color = _C.ink,
    this.accentColor = _C.accent,
    this.textAlign = TextAlign.left,
  });
  final String before;
  final String accent;
  final double size;
  final double maxWidth;
  final Color color;
  final Color accentColor;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final adjusted = width <= 640
        ? math.min(size, size >= 60 ? 43 : 38).toDouble()
        : size;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Semantics(
        header: true,
        child: RichText(
          textAlign: textAlign,
          text: TextSpan(
            style: _T.display(
              size: adjusted,
              color: color,
              weight: FontWeight.w600,
              height: 1.08,
            ),
            children: [
              TextSpan(text: before),
              TextSpan(
                text: accent,
                style: _T.display(
                  size: adjusted,
                  color: accentColor,
                  weight: FontWeight.w500,
                  height: 1.08,
                  italic: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _C.line),
      boxShadow: _shadowSmall,
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: _T.body(size: 13.5, weight: FontWeight.w600, height: 1.2),
    ),
  );
}

class _Checks extends StatelessWidget {
  const _Checks({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: _C.oliveSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.check, color: _C.olive, size: 13),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                items[i],
                style: _T.body(
                  size: 15,
                  color: _C.ink,
                  weight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        if (i != items.length - 1) const SizedBox(height: 14),
      ],
    ],
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.size,
    this.radius = 15,
    this.iconSize = 23,
  });
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double radius;
  final double iconSize;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: foreground, size: iconSize),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.text, {this.positive = false});
  final String text;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: positive ? _C.positiveSoft : _C.pendingSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: _T.body(
        size: 10.5,
        color: positive ? _C.positive : _C.pending,
        weight: FontWeight.w700,
        height: 1.1,
      ),
    ),
  );
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedSlide(
      offset: _hovered ? const Offset(0, -.04) : Offset.zero,
      duration: const Duration(milliseconds: 220),
      child: FilledButton.icon(
        onPressed: widget.onTap,
        iconAlignment: IconAlignment.end,
        icon: widget.icon == null
            ? const SizedBox.shrink()
            : Icon(widget.icon, size: 17),
        label: Text(widget.label),
        style: FilledButton.styleFrom(
          minimumSize: Size(0, widget.compact ? 42 : 50),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 24),
          backgroundColor: _hovered ? _C.accentDark : _C.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x47BE4B24),
          textStyle: _T.body(
            size: widget.compact ? 13 : 15,
            color: Colors.white,
            weight: FontWeight.w600,
            height: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      foregroundColor: _C.ink,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: _C.line, width: 1.5),
      textStyle: _T.body(
        size: 15,
        color: _C.ink,
        weight: FontWeight.w600,
        height: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    child: Text(label),
  );
}

class _TextButton extends StatelessWidget {
  const _TextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: _C.muted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: _T.body(size: 14, weight: FontWeight.w600, height: 1),
    ),
    child: Text(label),
  );
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child});
  final Widget child;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.ease,
      transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _hovered ? _shadowMedium : const [],
      ),
      child: widget.child,
    ),
  );
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.columns,
    required this.gap,
    required this.children,
  });
  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      final itemWidth = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(width: itemWidth, child: child),
        ],
      );
    },
  );
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.initiallyVisible = false,
  });
  final Widget child;
  final Duration delay;
  final bool initiallyVisible;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;
  bool _scheduled = false;
  ScrollPosition? _position;

  @override
  void initState() {
    super.initState();
    _visible = widget.initiallyVisible;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (_position != next) {
      _position?.removeListener(_check);
      _position = next?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _visible || _scheduled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * .9 && bottom > 0) {
      _scheduled = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _visible = true);
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) setState(() => _visible = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    offset: _visible ? Offset.zero : const Offset(0, .035),
    duration: const Duration(milliseconds: 700),
    curve: Curves.ease,
    child: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.ease,
      child: widget.child,
    ),
  );
}
