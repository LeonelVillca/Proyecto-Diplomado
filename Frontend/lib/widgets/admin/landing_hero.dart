import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      child: Stack(
        children: [
          // Hero content
          Padding(
            padding: const EdgeInsets.only(top: 80), // for navbar
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 55,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eyebrow
                                Row(
                                  children: [
                                    Container(width: 16, height: 2, color: const Color(0xFFC1622E)), // terracotta
                                    const SizedBox(width: 8),
                                    Text(
                                      'LA PLATAFORMA DE RESERVAS DE TARIJA',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF6B1233), // wine
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // H1
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.piazzolla(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF241512), // ink
                                      height: 1.08,
                                      letterSpacing: -0.5,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Lleva tu '),
                                      TextSpan(
                                        text: 'Restaurante\n',
                                        style: GoogleFonts.piazzolla(
                                          color: const Color(0xFF6B1233), // wine
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const TextSpan(text: 'al Siguiente Nivel'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Paragraph
                                Text(
                                  'Gestiona reservas en tiempo real, digitaliza tu menú y conecta con miles de clientes en el valle central.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF7A6A5C), // ink-soft
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Buttons
                                Row(
                                  children: [
                                    _HeroButtonPrimary(
                                      label: 'Crear cuenta gratis',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen()),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    _HeroButtonGhost(
                                      label: 'Explorar restaurantes',
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 48),
                                // Stats
                                Row(
                                  children: [
                                    _StatBadge('200+', 'Restaurantes activos'),
                                    const SizedBox(width: 32),
                                    _StatBadge('15k+', 'Reservas mensuales'),
                                    const SizedBox(width: 32),
                                    _StatBadge('4.9★', 'Calificación prom.'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right Column (Visual)
                      Expanded(
                        flex: 45,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(_controller),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Main visual block
                                Container(
                                  height: 500,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6B1233), Color(0xFF3A0A1B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(69, 11, 32, 0.20),
                                        blurRadius: 70,
                                        offset: Offset(0, 30),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Opacity(
                                      opacity: 0.3,
                                      child: Image.asset(
                                        'assets/restaurant_hero.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                                // Floating card 1
                                Positioned(
                                  top: 40,
                                  left: -30,
                                  child: _FloatingCard(
                                    icon: Icons.check_circle,
                                    iconColor: const Color(0xFF5C7A52), // sage
                                    title: 'Reserva confirmada',
                                    subtitle: 'Mesa para 4, 20:00',
                                  ),
                                ),
                                // Floating card 2
                                Positioned(
                                  bottom: 60,
                                  right: -20,
                                  child: _FloatingCard(
                                    icon: Icons.local_offer,
                                    iconColor: const Color(0xFFC1622E), // terracotta
                                    title: '15% off en vinos',
                                    subtitle: 'Con tu reserva hoy',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Navbar on top
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LandingNavbar(),
          ),
        ],
      ),
    );
  }
}

class _HeroButtonPrimary extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HeroButtonPrimary({required this.label, required this.onTap});

  @override
  State<_HeroButtonPrimary> createState() => _HeroButtonPrimaryState();
}

class _HeroButtonPrimaryState extends State<_HeroButtonPrimary> {
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF8C3350) : const Color(0xFF6B1233), // wine-soft : wine
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovered
                ? const [BoxShadow(color: Color.fromRGBO(107, 18, 51, 0.32), blurRadius: 26, offset: Offset(0, 12))]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.01,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroButtonGhost extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HeroButtonGhost({required this.label, required this.onTap});

  @override
  State<_HeroButtonGhost> createState() => _HeroButtonGhostState();
}

class _HeroButtonGhostState extends State<_HeroButtonGhost> {
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? const Color(0xFF6B1233) : const Color.fromRGBO(36, 21, 18, 0.10),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.manrope(
              color: _hovered ? const Color(0xFF6B1233) : const Color(0xFF241512),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.01,
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
        Text(value, style: GoogleFonts.piazzolla(color: const Color(0xFF241512), fontSize: 26, fontWeight: FontWeight.w700)), // ink
        Text(label, style: GoogleFonts.manrope(color: const Color(0xFF7A6A5C), fontSize: 11.5, fontWeight: FontWeight.w700)), // ink-soft
      ],
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FloatingCard({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6), // card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(36, 21, 18, 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(69, 11, 32, 0.10),
            blurRadius: 50,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(color: const Color(0xFF241512), fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(color: const Color(0xFF7A6A5C), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
