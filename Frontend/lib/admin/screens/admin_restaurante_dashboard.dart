import 'package:flutter/material.dart';
import '../../movil/providers/auth_provider.dart';
import '../widgets/admin_shell.dart';
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
  State<AdminRestauranteDashboard> createState() => _AdminRestauranteDashboardState();
}

class _AdminRestauranteDashboardState extends State<AdminRestauranteDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PerfilRestauranteScreen(),
    const GestionMesasScreen(),
    const GestionMenusScreen(),
    const Center(child: Text('Promociones (F4)', style: TextStyle(fontSize: 24, fontFamily: 'Karla'))),
    const GestionReservasScreen(),
    const GestionResenasScreen(),
    const SoporteRestauranteScreen(),
    const ReportesRestauranteScreen(),
  ];

  static const _sections = [
    SidebarSection(
      title: 'NEGOCIO',
      items: [
        SidebarItem(icon: Icons.restaurant_outlined, label: 'Perfil', index: 0),
        SidebarItem(icon: Icons.table_restaurant_outlined, label: 'Mesas', index: 1),
        SidebarItem(icon: Icons.menu_book_outlined, label: 'Menús', index: 2),
        SidebarItem(icon: Icons.local_offer_outlined, label: 'Promociones', index: 3),
      ],
    ),
    SidebarSection(
      title: 'OPERACIÓN',
      items: [
        SidebarItem(icon: Icons.calendar_month_outlined, label: 'Reservas', index: 4),
        SidebarItem(icon: Icons.star_outline, label: 'Reseñas', index: 5),
        SidebarItem(icon: Icons.support_agent_outlined, label: 'Soporte', index: 6),
        SidebarItem(icon: Icons.bar_chart_outlined, label: 'Reportes', index: 7),
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
      onLogout: () => auth.signOut(),
      sections: _sections,
      nombreUsuario: nombre,
      correoUsuario: correo,
      rolLabel: 'Admin Restaurante',
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _screens[_selectedIndex],
        ),
      ),
    );
  }
}
