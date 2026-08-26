import 'package:flutter/material.dart';

class SolicitudHero extends StatelessWidget {
  const SolicitudHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF3B0D1B), // Vino muy oscuro
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Únete a Mesa Chapaca hoy mismo.',
            style: TextStyle(
              fontFamily: 'BodoniModa',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Text(
              'Mesa Chapaca cuenta con todas las herramientas que necesitas para atraer clientes, operar de manera más eficiente y fortalecer las relaciones con ellos.',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 18,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
