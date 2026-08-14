import 'package:flutter/material.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_benefits.dart';

class AdminLandingScreen extends StatelessWidget {
  const AdminLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE), // Crema
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: LandingNavbar(),
          ),
          const SliverToBoxAdapter(
            child: LandingHero(),
          ),
          const SliverToBoxAdapter(
            child: LandingBenefits(),
          ),
        ],
      ),
    );
  }
}
