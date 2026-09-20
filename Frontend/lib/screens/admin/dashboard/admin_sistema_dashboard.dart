import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/widgets/admin/admin_shell.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/moderacion/moderacion_screen.dart';
import 'package:frontend/screens/admin/solicitudes/solicitudes_screen.dart';
import 'package:frontend/screens/admin/usuarios/usuarios_screen.dart';
import 'package:frontend/screens/admin/usuarios/roles_crud_screen.dart';
import 'package:frontend/screens/admin/usuarios/asignacion_roles_screen.dart';
import 'package:frontend/screens/admin/usuarios/asignacion_permisos_screen.dart';
import 'package:frontend/screens/admin/soporte/admin_soporte_screen.dart';
import 'package:frontend/screens/admin/restaurantes/restaurantes_screen.dart';

class AdminSistemaDashboard extends StatefulWidget {
  const AdminSistemaDashboard({super.key});

  @override
  State<AdminSistemaDashboard> createState() => _AdminSistemaDashboardState();
}

class _AdminSistemaDashboardState extends State<AdminSistemaDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SolicitudesScreen(),
    const UsuariosScreen(),
    const RestaurantesScreen(),
    const RolesCrudScreen(),
    const AsignacionRolesScreen(),
    const AsignacionPermisosScreen(),
    const AdminSoporteScreen(),
    const ModeracionScreen(),
  ];

  static const _sections = [
    SidebarSection(
      title: 'MENÚ',
      items: [
        SidebarItem(icon: Icons.assignment_ind_outlined, label: 'Solicitudes', codigo: 'menu_solicitudes', index: 0),
        SidebarItem(icon: Icons.people_outline, label: 'Usuarios', codigo: 'menu_usuarios', index: 1),
        SidebarItem(icon: Icons.restaurant_outlined, label: 'Restaurantes', codigo: 'menu_restaurantes', index: 2),
        SidebarItem(icon: Icons.shield_outlined, label: 'Roles', codigo: 'menu_roles', index: 3),
        SidebarItem(icon: Icons.manage_accounts_outlined, label: 'Asignar Roles', codigo: 'menu_asignar_roles', index: 4),
        SidebarItem(icon: Icons.vpn_key_outlined, label: 'Permisos', codigo: 'menu_permisos', index: 5),
      ],
    ),
    SidebarSection(
      title: 'GENERAL',
      items: [
        SidebarItem(icon: Icons.support_agent_outlined, label: 'Soporte', codigo: 'menu_soporte', index: 6),
        SidebarItem(icon: Icons.reviews_outlined, label: 'Moderación', codigo: 'menu_moderacion', index: 7),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombre = auth.displayName ?? 'Administrador';
    final correo = auth.email ?? 'admin@mesachapaca.com';

    // Filtrar menús según los permisos del usuario
    final filteredSections = _sections.map((section) {
      final allowedItems = section.items.where((item) => auth.hasPermiso(item.codigo)).toList();
      return SidebarSection(title: section.title, items: allowedItems);
    }).where((section) => section.items.isNotEmpty).toList();

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
      sections: filteredSections,
      nombreUsuario: nombre,
      correoUsuario: correo,
      rolLabel: 'Admin Sistema',
      body: _screens[_selectedIndex],
    );
  }
}
