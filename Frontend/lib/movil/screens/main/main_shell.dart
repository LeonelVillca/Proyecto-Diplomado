import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'home_tab.dart';
import 'location_screen.dart';
import 'profile_screen.dart';
import 'reservations_screen.dart';

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
      body : SafeArea(
        top: true,
        bottom:false,
        child:  IndexedStack(
          index: _tab.index,
          children: _screens,
       ),
      ),
      bottomNavigationBar: AppBottomNav(
         current: _tab,
         onSelected: (tab) => setState(() => _tab = tab),
        ),
      );
  }
}