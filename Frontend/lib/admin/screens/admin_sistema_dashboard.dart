import 'package:flutter/material.dart';
import '../../movil/providers/auth_provider.dart';
import '../widgets/admin_shell.dart';
import 'moderacion_screen.dart';
import 'solicitudes_screen.dart';
import 'usuarios_roles_screen.dart';

class AdminSistemaDashboard extends StatefulWidget {
  const AdminSistemaDashboard({super.key});

  @override
  State<AdminSistemaDashboard> createState() => _AdminSistemaDashboardState();
}

class _AdminSistemaDashboardState extends State<AdminSistemaDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SolicitudesScreen(),
    const UsuariosRolesScreen(),
    const ModeracionScreen(),
  ];

  static const _sections = [
    SidebarSection(
      title: 'MENÚ',
      items: [
        SidebarItem(icon: Icons.assignment_ind_outlined, label: 'Solicitudes', index: 0),
        SidebarItem(icon: Icons.people_outline, label: 'Usuarios y Roles', index: 1),
      ],
    ),
    SidebarSection(
      title: 'GENERAL',
      items: [
        SidebarItem(icon: Icons.reviews_outlined, label: 'Moderación', index: 2),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombre = auth.displayName ?? 'Administrador';
    final correo = auth.email ?? 'admin@mesachapaca.com';

    return AdminShell(
      selectedIndex: _selectedIndex,
      onItemSelected: (i) => setState(() => _selectedIndex = i),
      onLogout: () => auth.signOut(),
      sections: _sections,
      nombreUsuario: nombre,
      correoUsuario: correo,
      rolLabel: 'Admin Sistema',
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
