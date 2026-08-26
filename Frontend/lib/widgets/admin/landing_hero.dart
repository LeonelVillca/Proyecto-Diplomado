import 'package:flutter/material.dart';
import 'landing_navbar.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';

class LandingHero extends StatefulWidget {
  const LandingHero({super.key});

  @override
  State<LandingHero> createState() => _LandingHeroState();
}

class _LandingHeroState extends State<LandingHero> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 750,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/restaurant_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/fondo_tarija.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xDD0D0401),
                    Color(0xBB1A0A05),
                    Color(0x661A0A05),
                    Color(0x221A0A05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Bottom dark fade
          Positioned(
            bottom: 0, left: 0, right: 0, height: 140,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF0D0401)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Navbar on top of hero
          Positioned(
            top: 0, left: 0, right: 0,
            child: const LandingNavbar(),
          ),

          // Hero content
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 6,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 60),
                                // Tag line
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '✦  La plataforma de reservas de Tarija',
                                    style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Karla',
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Main heading
                                const Text(
                                  'Lleva tu\nRestaurante\nal Siguiente\nNivel',
                                  style: TextStyle(
                                    fontFamily: 'BodoniModa',
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.08,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: 56,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Gestiona reservas en tiempo real, digitaliza tu menú\ny conecta con miles de clientes en Tarija.',
                                  style: TextStyle(
                                    fontFamily: 'Karla',
                                    fontSize: 18,
                                    color: Color(0xCCFFFFFF),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // CTA Buttons
                                Row(
                                  children: [
                                    _HeroButton(
                                      label: 'Registrar mi Restaurante',
                                      isPrimary: true,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen()),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    _HeroButton(
                                      label: 'Iniciar Sesión',
                                      isPrimary: false,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 36),
                                // Social proof
                                Row(
                                  children: [
                                    _StatBadge('200+', 'Clientes activos'),
                                    _Divider(),
                                    _StatBadge('50+', 'Restaurantes'),
                                    _Divider(),
                                    _StatBadge('4.9★', 'Calificación promedio'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Expanded(flex: 4, child: SizedBox()),
                    ],
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

class _HeroButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.isPrimary, required this.onTap});

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered ? const Color(0xFFE8C547) : const Color(0xFFD4AF37))
                : Colors.white.withValues(alpha: _hovered ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(6),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: widget.isPrimary && _hovered
                ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isPrimary ? const Color(0xFF1A0A00) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Karla',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa')),
        Text(label, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontFamily: 'Karla')),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 24), width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2));
  }
}
