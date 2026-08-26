import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/widgets/movil/navigation/app_bottom_nav.dart';
import 'package:frontend/screens/movil/favorites/favorites_screen.dart';
import 'package:frontend/screens/movil/home/home_screen.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';
import 'package:frontend/screens/movil/location/location_screen.dart';
import 'package:frontend/screens/movil/profile/profile_screen.dart';
import 'package:frontend/screens/movil/reservations/reservations_screen.dart';

/// Contenedor principal tras iniciar sesión: pestañas + barra flotante.
///
/// Usa [IndexedStack] para conservar el estado de cada pestaña al navegar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  HomeTab _tab = HomeTab.inicio;

  static const _screens = [
    HomeScreen(),
    ReservationsScreen(),
    FavoritesScreen(),
    LocationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _tab.index,
        children: _screens,
      ),

      bottomNavigationBar: AppBottomNav(
         current: _tab,
         onSelected: (tab) => setState(() => _tab = tab),
        ),
      );
  }
}