import 'package:flutter/material.dart';
import '../../movil/providers/auth_provider.dart';
import '../widgets/admin_shell.dart';
import 'admin_login_screen.dart';
import 'admin_restaurante/dashboard_resumen_screen.dart';
import 'gestion_menus_screen.dart';
import 'gestion_mesas_screen.dart';
import 'gestion_reservas_screen.dart';
import 'gestion_resenas_screen.dart';
import 'perfil_restaurante_screen.dart';
import 'admin_restaurante/soporte_restaurante_screen.dart';
import 'admin_restaurante/reportes_restaurante_screen.dart';

class AdminRestauranteDashboard extends StatefulWidget {
  const AdminRestauranteDashboard({super.key});

  @override
  State<AdminRestauranteDashboard> createState() =>
      _AdminRestauranteDashboardState();
}

class _AdminRestauranteDashboardState
    extends State<AdminRestauranteDashboard> {
  int _selectedIndex = 0;

  // ── índice 0 = nueva pantalla resumen ─────────────────────
  // ── índice 1 = Perfil (desplazado desde 0) ────────────────
  // ── índices 2..8 = resto desplazados +1 ───────────────────
  final List<Widget> _screens = [
    const DashboardResumenScreen(),
    const PerfilRestauranteScreen(),
    const GestionMesasScreen(),
    const GestionMenusScreen(),
    const Center(
      child: Text(
        'Promociones (F4)',
        style: TextStyle(fontSize: 24, fontFamily: 'Karla'),
      ),
    ),
    const GestionReservasScreen(),
    const GestionResenasScreen(),
    const SoporteRestauranteScreen(),
    const ReportesRestauranteScreen(),
  ];

  static const _sections = [
    SidebarSection(
      title: 'NEGOCIO',
      items: [
        SidebarItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          index: 0,
        ),
        SidebarItem(
          icon: Icons.restaurant_outlined,
          label: 'Perfil',
          index: 1,
        ),
        SidebarItem(
          icon: Icons.table_restaurant_outlined,
          label: 'Mesas',
          index: 2,
        ),
        SidebarItem(
          icon: Icons.menu_book_outlined,
          label: 'Menús',
          index: 3,
        ),
        SidebarItem(
          icon: Icons.local_offer_outlined,
          label: 'Promociones',
          index: 4,
        ),
      ],
    ),
    SidebarSection(
      title: 'OPERACIÓN',
      items: [
        SidebarItem(
          icon: Icons.calendar_month_outlined,
          label: 'Reservas',
          index: 5,
        ),
        SidebarItem(
          icon: Icons.star_outline,
          label: 'Reseñas',
          index: 6,
        ),
        SidebarItem(
          icon: Icons.support_agent_outlined,
          label: 'Soporte',
          index: 7,
        ),
        SidebarItem(
          icon: Icons.bar_chart_outlined,
          label: 'Reportes',
          index: 8,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombre = auth.displayName ?? 'Restaurantero';
    final correo = auth.email ?? 'restaurante@mesachapaca.com';

    return AdminShell(
      selectedIndex: _selectedIndex,
      onItemSelected: (i) => setState(() => _selectedIndex = i),
      onLogout: () async {
        await auth.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            (route) => false,
          );
        }
      },
      sections: _sections,
      nombreUsuario: nombre,
      correoUsuario: correo,
      rolLabel: 'Admin Restaurante',
      body: _screens[_selectedIndex],
    );
  }
}
