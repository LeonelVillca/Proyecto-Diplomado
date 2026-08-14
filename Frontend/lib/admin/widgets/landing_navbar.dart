import 'package:flutter/material.dart';
import '../screens/solicitud_registro_screen.dart';
import '../screens/admin_login_screen.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4EE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Color(0xFF6B1A35), size: 32),
              const SizedBox(width: 12),
              Text(
                'Mesa Chapaca',
                style: TextStyle(
                  color: const Color(0xFF6B1A35), // Vino
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BodoniModa',
                ),
              ),
            ],
          ),
          Row(
            children: [
              _NavText('Más Reservas'),
              const SizedBox(width: 32),
              _NavText('Gestión Simple'),
              const SizedBox(width: 32),
              _NavText('Visibilidad en Tarija'),
              const SizedBox(width: 40),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B1A35),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Acceso'),
              ),
              const SizedBox(width: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Comienza'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _NavText extends StatelessWidget {
  final String text;
  const _NavText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontFamily: 'Karla',
      ),
    );
  }
}
