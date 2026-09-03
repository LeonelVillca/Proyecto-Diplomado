import 'package:frontend/widgets/admin/landing_footer.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingBenefits extends StatelessWidget {
  const LandingBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHowItWorks(),
        _SectionBenefits(),
        _SectionTestimonios(),
        _SectionStats(),
        LandingFooter(),
      ],
    );
  }
}

// ─── CÓMO FUNCIONA ────────────────────────────────────────────────────────────
class _SectionHowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAE0C9), // paper-deep
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              SectionLabel('CÓMO FUNCIONA'),
              const SizedBox(height: 16),
              Text(
                'Tres pasos para empezar',
                style: GoogleFonts.piazzolla(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF241512), // ink
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepCard(
                    number: '01',
                    icon: Icons.description_outlined,
                    title: 'Envía tu solicitud',
                    description:
                        'Completa el formulario con los datos de tu restaurante. Revisamos tu solicitud en menos de 24 horas.',
                  ),
                  const SizedBox(width: 24),
                  _StepCard(
                    number: '02',
                    icon: Icons.verified_outlined,
                    title: 'Aprobación y acceso',
                    description:
                        'Una vez aprobado, recibirás tus credenciales para acceder al panel de administración exclusivo.',
                  ),
                  const SizedBox(width: 24),
                  _StepCard(
                    number: '03',
                    icon: Icons.rocket_launch_outlined,
                    title: 'Gestiona y crece',
                    description:
                        'Configura tu menú, mesas y horarios. Empieza a recibir reservas en tiempo real desde el primer día.',
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

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.transparent, // Uses background of section
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF6B1233), // wine
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF241512), // ink
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.manrope(
                fontSize: 15,
                color: const Color(0xFF7A6A5C), // ink-soft
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BENEFICIOS ───────────────────────────────────────────────────────────────
class _SectionBenefits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EEE0), // paper
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Container(
            padding: const EdgeInsets.all(64),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B1233), Color(0xFF3A0A1B)], // wine -> wine-dark
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(107, 18, 51, 0.20),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text Column
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabelDark('PARA RESTAURANTES'),
                      const SizedBox(height: 16),
                      Text(
                        'Todo lo que necesitas\npara crecer',
                        style: GoogleFonts.piazzolla(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Diseñado exclusivamente para la gastronomía tarijeña. Herramientas simples, resultados poderosos.',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _BenefitRow(title: 'Reservas en tiempo real', description: 'Recibe y gestiona reservas al instante.'),
                      const SizedBox(height: 20),
                      const _BenefitRow(title: 'Menú digital interactivo', description: 'Presenta tus platillos con fotos y precios actualizados.'),
                      const SizedBox(height: 20),
                      const _BenefitRow(title: 'Mayor visibilidad', description: 'Atrae nuevos clientes locales y turistas.'),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B1233), // wine
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Registra tu restaurante',
                          style: GoogleFonts.manrope(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 80),
                // Visual Column
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Opacity(
                          opacity: 0.8,
                          child: Image.asset(
                            'assets/tarija_food.png',
                            height: 400,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 400,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Floating stat 1
                      Positioned(
                        top: 20,
                        right: -10,
                        child: _GlassStat(title: '+40%', subtitle: 'más reservas'),
                      ),
                      // Floating stat 2
                      Positioned(
                        bottom: 40,
                        left: -20,
                        child: _GlassStat(title: '120+', subtitle: 'restaurantes activos'),
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

class _BenefitRow extends StatelessWidget {
  final String title;
  final String description;

  const _BenefitRow({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(Icons.check_circle, color: Color(0xFFC08A1E), size: 20), // gold
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassStat extends StatelessWidget {
  final String title;
  final String subtitle;
  const _GlassStat({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.piazzolla(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TESTIMONIOS ──────────────────────────────────────────────────────────────
class _SectionTestimonios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EEE0), // paper
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              SectionLabel('TESTIMONIOS'),
              const SizedBox(height: 16),
              Text(
                'Lo que dicen nuestros\nrestaurantes',
                style: GoogleFonts.piazzolla(
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF241512), // ink
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _TestimonioCard(
                    nombre: 'Carlos Montaño',
                    restaurante: 'La Casona Tarijeña',
                    texto:
                        '"Desde que usamos Mesa Chapaca, las reservas duplicaron. Nuestros clientes llegan con todo coordinado y la experiencia mejoró muchísimo."',
                    stars: 5,
                  ),
                  SizedBox(width: 24),
                  _TestimonioCard(
                    nombre: 'María Flores',
                    restaurante: 'El Viñedo del Sur',
                    texto:
                        '"El panel de administración es muy intuitivo. Gestionar mesas y menús ahora me toma minutos, antes era un caos de llamadas."',
                    stars: 5,
                  ),
                  SizedBox(width: 24),
                  _TestimonioCard(
                    nombre: 'Roberto Vega',
                    restaurante: 'Rincón Criollo',
                    texto:
                        '"Las reseñas nos ayudaron a mejorar nuestro servicio. Podemos responder directamente y los clientes lo valoran mucho."',
                    stars: 5,
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

class _TestimonioCard extends StatelessWidget {
  final String nombre;
  final String restaurante;
  final String texto;
  final int stars;

  const _TestimonioCard({
    required this.nombre,
    required this.restaurante,
    required this.texto,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF6), // card
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color.fromRGBO(36, 21, 18, 0.10)), // line
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(69, 11, 32, 0.10),
              blurRadius: 50,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                stars,
                (_) => const Icon(Icons.star_rounded, color: Color(0xFFC08A1E), size: 20), // gold
              ),
            ),
            const SizedBox(height: 24),
            Text(
              texto,
              style: GoogleFonts.piazzolla(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF241512), // ink
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEAE0C9), // paper-deep
                  radius: 24,
                  child: Text(
                    nombre[0],
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF6B1233), // wine
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF241512), // ink
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        restaurante,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF7A6A5C), // ink-soft
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STATS ─────────────────────────────────────────────────────────────────
class _SectionStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6B1233), // wine
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StatItem('50+', 'Restaurantes afiliados'),
              _StatDivider(),
              _StatItem('200+', 'Clientes satisfechos'),
              _StatDivider(),
              _StatItem('1,200+', 'Reservas gestionadas'),
              _StatDivider(),
              _StatItem('4.9/5', 'Calificación promedio'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.piazzolla(fontSize: 44, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: Colors.white.withValues(alpha: 0.2));
  }
}

// ─── FOOTER ───────────────────────────────────────────────────────────────────


