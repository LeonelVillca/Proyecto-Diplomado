import 'package:flutter/material.dart';

class LandingBenefits extends StatelessWidget {
  const LandingBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Todo lo que necesitas para crecer',
                style: const TextStyle(
                  fontFamily: 'BodoniModa',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B1A35),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Diseñado exclusivamente para la gastronomía tarijeña',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BenefitCard(
                    icon: Icons.table_restaurant_outlined,
                    title: 'Gestión de Mesas y Reservas',
                    description: 'Recibe notificaciones en tiempo real y gestiona tus mesas sin llamadas ni confusiones.',
                  ),
                  const SizedBox(width: 32),
                  _BenefitCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Menú Digital Interactivo',
                    description: 'Muestra tus platillos con fotos y precios actualizados al instante, sin costos de impresión.',
                  ),
                  const SizedBox(width: 32),
                  _BenefitCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Mayor Visibilidad',
                    description: 'Atrae nuevos clientes locales y turistas que buscan la mejor gastronomía en Tarija.',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F4EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B1A35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6B1A35), size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'BodoniModa',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B1A35),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
