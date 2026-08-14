import 'package:flutter/material.dart';
import '../screens/solicitud_registro_screen.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F4EE),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potencia tu\nRestaurante en Tarija',
                      style: const TextStyle(
                        fontFamily: 'BodoniModa',
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B1A35),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Únete a la plataforma líder de reservas. Gestiona tus mesas, digitaliza tu menú y llega a miles de clientes buscando dónde comer hoy.',
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 20,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SolicitudRegistroScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B1A35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF6B1A35).withOpacity(0.5),
                      ),
                      child: const Text(
                        'Únete a Mesa Chapaca Hoy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                flex: 1,
                child: Container(
                  height: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/fondo_tarija.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
