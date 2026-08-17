import 'package:flutter/material.dart';

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
        _SectionFooter(),
      ],
    );
  }
}

// ─── CÓMO FUNCIONA ────────────────────────────────────────────────────────────
class _SectionHowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0401),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabel('¿CÓMO FUNCIONA?'),
              const SizedBox(height: 16),
              const Text(
                'Tres pasos para empezar',
                style: TextStyle(
                  fontFamily: 'BodoniModa',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
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
          color: const Color(0xFF1A0D05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A1A0A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'BodoniModa',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFD4AF37), size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'BodoniModa',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                color: Color(0xAAFFFFFF),
                height: 1.6,
              ),
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
      color: const Color(0xFFF9F5EE),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabelDark('BENEFICIOS'),
              const SizedBox(height: 16),
              const Text(
                'Todo lo que necesitas\npara crecer',
                style: TextStyle(
                  fontFamily: 'BodoniModa',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A0A00),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Diseñado exclusivamente para la gastronomía tarijeña.\nHerramientas simples, resultados poderosos.',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 18,
                  color: Color(0xFF6B5A4A),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 72),
              // Imagen grande + lista de beneficios
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/tarija_food.png',
                        height: 500,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 500,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.restaurant, size: 80, color: Color(0xFFD4AF37)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _BenefitRow(
                          icon: Icons.calendar_month_outlined,
                          title: 'Reservas en tiempo real',
                          description:
                              'Recibe y gestiona reservas al instante. Confirma, rechaza o reasigna mesas sin depender del teléfono.',
                        ),
                        _BenefitRow(
                          icon: Icons.menu_book_outlined,
                          title: 'Menú digital interactivo',
                          description:
                              'Presenta tus platillos con fotos y precios actualizados. Tus clientes los verán antes de llegar.',
                        ),
                        _BenefitRow(
                          icon: Icons.trending_up_outlined,
                          title: 'Mayor visibilidad en Tarija',
                          description:
                              'Aparece en el ranking de los mejores restaurantes y atrae nuevos clientes locales y turistas.',
                        ),
                        _BenefitRow(
                          icon: Icons.star_outline_rounded,
                          title: 'Reseñas y reputación',
                          description:
                              'Responde a los comentarios de tus clientes y construye una reputación sólida en la plataforma.',
                        ),
                        _BenefitRow(
                          icon: Icons.bar_chart_outlined,
                          title: 'Reportes y estadísticas',
                          description:
                              'Accede a métricas de visitas, reservas y calificaciones para tomar mejores decisiones.',
                        ),
                      ],
                    ),
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

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'BodoniModa',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A0A00),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    color: Color(0xFF6B5A4A),
                    height: 1.5,
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

// ─── TESTIMONIOS ──────────────────────────────────────────────────────────────
class _SectionTestimonios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A00),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              _SectionLabel('TESTIMONIOS'),
              const SizedBox(height: 16),
              const Text(
                'Lo que dicen nuestros\nrestaurantes',
                style: TextStyle(
                  fontFamily: 'BodoniModa',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
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
          color: const Color(0xFF2A1408),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A2010)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                stars,
                (_) => const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              texto,
              style: const TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                color: Color(0xCCFFFFFF),
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  radius: 22,
                  child: Text(
                    nombre[0],
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BodoniModa',
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Karla', fontSize: 15)),
                    Text(restaurante, style: const TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Karla', fontSize: 13)),
                  ],
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
      color: const Color(0xFFD4AF37),
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
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
        Text(value, style: const TextStyle(fontFamily: 'BodoniModa', fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF1A0A00))),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontFamily: 'Karla', fontSize: 15, color: Color(0x99000000))),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: const Color(0x331A0A00));
  }
}

// ─── FOOTER ───────────────────────────────────────────────────────────────────
class _SectionFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0401),
      child: Column(
        children: [
          // Footer Main
          Container(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
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
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Mesa Chapaca',
                                style: TextStyle(
                                  fontFamily: 'BodoniModa',
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'La plataforma de reservas líder\npara restaurantes en Tarija, Bolivia.',
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 15,
                              color: Color(0x88FFFFFF),
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
                          const Text('Plataforma', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'BodoniModa', fontSize: 16, fontWeight: FontWeight.bold)),
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
                          const Text('Soporte', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'BodoniModa', fontSize: 16, fontWeight: FontWeight.bold)),
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
                          const Text('Contacto', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'BodoniModa', fontSize: 16, fontWeight: FontWeight.bold)),
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
              border: Border(top: BorderSide(color: Color(0xFF2A1408))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '© 2026 Mesa Chapaca. Todos los derechos reservados.',
                  style: TextStyle(fontFamily: 'Karla', color: Color(0x55FFFFFF), fontSize: 13),
                ),
                const Text(
                  'Hecho con ❤ en Tarija, Bolivia',
                  style: TextStyle(fontFamily: 'Karla', color: Color(0x55FFFFFF), fontSize: 13),
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
          child: Text(l, style: const TextStyle(fontFamily: 'Karla', color: Color(0x88FFFFFF), fontSize: 15)),
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
        Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontFamily: 'Karla', color: Color(0x88FFFFFF), fontSize: 15)),
      ],
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontFamily: 'Karla',
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
      ),
    );
  }
}

class _SectionLabelDark extends StatelessWidget {
  final String text;
  const _SectionLabelDark(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontFamily: 'Karla',
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
      ),
    );
  }
}
