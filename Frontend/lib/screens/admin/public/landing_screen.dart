import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';
import 'package:frontend/widgets/admin/landing_benefits.dart';
import 'package:frontend/widgets/admin/landing_hero.dart';
import 'package:frontend/widgets/admin/landing_navbar.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class AdminLandingScreen extends StatefulWidget {
  const AdminLandingScreen({super.key});

  @override
  State<AdminLandingScreen> createState() => _AdminLandingScreenState();
}

class _AdminLandingScreenState extends State<AdminLandingScreen> {
  final _scrollController = ScrollController();
  final _mainKey = GlobalKey();
  final _howKey = GlobalKey();
  final _benefitsKey = GlobalKey();
  final _restaurantsKey = GlobalKey();
  final _contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  void _openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen()),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingPalette.paper,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: LandingHero(
                  key: _mainKey,
                  onRegister: _openRegistration,
                  onExplore: () => _scrollTo(_restaurantsKey),
                ),
              ),
              SliverToBoxAdapter(
                child: LandingBenefits(
                  howKey: _howKey,
                  benefitsKey: _benefitsKey,
                  restaurantsKey: _restaurantsKey,
                  contactKey: _contactKey,
                  onRegister: _openRegistration,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: LandingNavbar(
              onBenefits: () => _scrollTo(_benefitsKey),
              onHowItWorks: () => _scrollTo(_howKey),
              onRestaurants: () => _scrollTo(_restaurantsKey),
              onContact: () => _scrollTo(_contactKey),
              onLogin: _openLogin,
              onRegister: _openRegistration,
            ),
          ),
        ],
      ),
    );
  }
}
