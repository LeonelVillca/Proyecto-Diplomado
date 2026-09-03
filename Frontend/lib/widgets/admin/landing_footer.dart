import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingFooter extends StatelessWidget { const LandingFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3A0A1B), // wine-dark
      child: Column(
        children: [
          // Footer Main
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC08A1E), // gold
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Mesa Chapaca',
                                style: GoogleFonts.piazzolla(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'La plataforma de reservas líder\npara restaurantes en Tarija, Bolivia.',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              _SocialBtn(Icons.facebook),
                              const SizedBox(width: 12),
                              _SocialBtn(Icons.camera_alt_outlined),
                              const SizedBox(width: 12),
                              _SocialBtn(Icons.language),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Links
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plataforma', style: GoogleFonts.manrope(color: const Color(0xFFC08A1E), fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          ..._footerLinks(['Cómo funciona', 'Beneficios', 'Restaurantes', 'Solicitar acceso']),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Soporte', style: GoogleFonts.manrope(color: const Color(0xFFC08A1E), fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          ..._footerLinks(['Preguntas frecuentes', 'Contacto', 'Términos de uso', 'Privacidad']),
                        ],
                      ),
                    ),
                    // Contact
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contacto', style: GoogleFonts.manrope(color: const Color(0xFFC08A1E), fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          _ContactItem(Icons.location_on_outlined, 'Tarija, Bolivia'),
                          const SizedBox(height: 14),
                          _ContactItem(Icons.email_outlined, 'contacto@mesachapaca.bo'),
                          const SizedBox(height: 14),
                          _ContactItem(Icons.phone_outlined, '+591 4 6XX-XXXX'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer Bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 60),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 Mesa Chapaca. Todos los derechos reservados.',
                  style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                Text(
                  'Hecho en el valle de Tarija, Bolivia.',
                  style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _footerLinks(List<String> links) {
    return links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l, style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
        )).toList();
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  const _SocialBtn(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3A2010)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0x88FFFFFF), size: 18),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC08A1E), size: 18),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
      ],
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: const Color(0xFFC1622E)),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.manrope(
            color: const Color(0xFF6B1233), // wine
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class SectionLabelDark extends StatelessWidget {
  final String text;
  const SectionLabelDark(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: const Color(0xFFC1622E)),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.manrope(
            color: const Color(0xFFF5EEE0), // light paper
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}


