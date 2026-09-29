import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';

import 'package:frontend/widgets/movil/navigation/app_bottom_nav.dart';
import 'package:frontend/screens/movil/home/home_screen.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';
import 'package:frontend/screens/movil/location/location_screen.dart';
import 'package:frontend/screens/movil/profile/profile_screen.dart';
import 'package:frontend/screens/movil/reservations/reservations_screen.dart';
import 'package:frontend/services/movil/notifications_service.dart';

/// Contenedor principal tras iniciar sesión: pestañas + barra flotante.
/// Usa IndexedStack para conservar el estado de cada pestaña.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static _MainShellState? _activeState;

  static void openReservations() => _activeState?._showReservations();
  static void openHome() => _activeState?._showHome();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  HomeTab _tab = HomeTab.inicio;

  @override
  void initState() {
    super.initState();
    MainShell._activeState = this;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationsService.start(
          onOpenReservation: () {
            if (mounted) _showReservations();
          },
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationsService.refreshDeviceRegistration();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (identical(MainShell._activeState, this)) MainShell._activeState = null;
    super.dispose();
  }

  void _showReservations() => setState(() => _tab = HomeTab.reservas);
  void _showHome() => setState(() => _tab = HomeTab.inicio);

  List<Widget> get _screens => [
    HomeScreen(),
    LocationScreen(),
    ReservationsScreen(isActive: _tab == HomeTab.reservas),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConsumerColors.background,
      extendBody: true,
      body: IndexedStack(index: _tab.index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        current: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}
