import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_hero.dart';
import 'package:frontend/widgets/admin/landing_benefits.dart';

class AdminLandingScreen extends StatelessWidget {
  const AdminLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEE0), // paper
      body: SingleChildScrollView(
        child: Column(
          children: const [
            LandingHero(),   // Hero contiene el Navbar encima
            LandingBenefits(), // Cómo funciona + beneficios + testimonios + stats + footer
          ],
        ),
      ),
    );
  }
}
