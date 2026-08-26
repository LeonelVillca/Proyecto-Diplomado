import 'package:flutter/material.dart';

class SolicitudFooter extends StatelessWidget {
  const SolicitudFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A), // Negro casi absoluto
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 60,
            runSpacing: 40,
            children: const [
              _FooterColumn(
                title: 'SOLUCIONES',
                items: ['Software de reservas', 'Soluciones de marketing', 'Gestión de mesas', 'Experiencias', 'Servicios de consultoría'],
              ),
              _FooterColumn(
                title: '¿POR QUÉ MESA CHAPACA?',
                items: ['Para restaurantes', 'Para grupos de restaurantes', 'Para bares', 'Frente a competidores'],
              ),
              _FooterColumn(
                title: 'MÁS',
                items: ['Sitio de restaurante', 'Acerca de Nosotros', 'Prensa', 'Blog', 'Recursos'],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Karla',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'Karla',
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
