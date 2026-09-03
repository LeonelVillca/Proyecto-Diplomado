import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingNavbar extends StatefulWidget {
  final bool showLinks;
  
  const LandingNavbar({super.key, this.showLinks = true});

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar> {
  String? _hoveredNav;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 0),
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xCCF5EEE0), // paper with opacity
            border: Border(bottom: BorderSide(color: Color.fromRGBO(36, 21, 18, 0.10), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
          Row(
            children: [
              Image.asset(
                'assets/icon_app.png',
                height: 42,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Mesa ',
                      style: GoogleFonts.piazzolla(
                        color: const Color(0xFF241512), // ink
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Chapaca',
                      style: GoogleFonts.piazzolla(
                        color: const Color(0xFFC08A1E), // gold or accent
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nav Links
          if (widget.showLinks)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    _NavLink('Beneficios', 'beneficios'),
                const SizedBox(width: 36),
                _NavLink('Cómo Funciona', 'como'),
                const SizedBox(width: 36),
                _NavLink('Restaurantes', 'restaurantes'),
                const SizedBox(width: 36),
                _NavLink('Contacto', 'contacto'),
                const SizedBox(width: 40),

                // Acceso
                _GhostButton(
                  label: 'Iniciar sesión',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  ),
                ),
                const SizedBox(width: 14),

                // Comienza
                _PrimaryButton(
                  label: 'Crear cuenta',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen()),
                  ),
                ),
              ], // closes inner Row children
            ), // closes inner Row
          ), // closes FittedBox
        ), // closes Expanded
    ], // closes outer Row children
  ), // closes outer Row
), // closes Container
), // closes BackdropFilter
); // closes ClipRRect
}
}

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: _hovered ? const Color(0xFF6B1233) : const Color.fromRGBO(36, 21, 18, 0.10),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.manrope(
              color: _hovered ? const Color(0xFF6B1233) : const Color(0xFF241512),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.01,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF8C3350) : const Color(0xFF6B1233),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovered
                ? [
                    const BoxShadow(
                      color: Color.fromRGBO(107, 18, 51, 0.32),
                      blurRadius: 26,
                      offset: Offset(0, 12),
                    ),
                  ]
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

class _NavLink extends StatefulWidget {
  final String text;
  final String id;
  const _NavLink(this.text, this.id);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: GoogleFonts.manrope(
              color: _hovered ? const Color(0xFF6B1233) : const Color(0xFF7A6A5C), // wine : ink-soft
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: _hovered ? 30 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF6B1233), // wine
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
