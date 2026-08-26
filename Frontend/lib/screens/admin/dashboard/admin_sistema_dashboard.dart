import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/widgets/admin/admin_shell.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/moderacion/moderacion_screen.dart';
import 'package:frontend/screens/admin/solicitudes/solicitudes_screen.dart';
import 'package:frontend/screens/admin/usuarios/usuarios_roles_screen.dart';

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
      rolLabel: 'Admin Sistema',
      body: _screens[_selectedIndex],
    );
  }
}
