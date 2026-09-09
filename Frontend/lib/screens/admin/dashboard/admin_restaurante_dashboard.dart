import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/perfil_restaurante_model.dart';
import 'package:frontend/screens/admin/public/onboarding_restaurante_screen.dart';
import 'package:frontend/widgets/admin/admin_shell.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/admin_restaurante/dashboard_resumen_screen.dart';
import 'package:frontend/screens/admin/menus/gestion_menus_screen.dart';
import 'package:frontend/screens/admin/mesas/gestion_mesas_screen.dart';
import 'package:frontend/screens/admin/reservas/gestion_reservas_screen.dart';
import 'package:frontend/screens/admin/resenas/gestion_resenas_screen.dart';
import 'package:frontend/screens/admin/perfil/perfil_restaurante_screen.dart';
import 'package:frontend/screens/admin/admin_restaurante/soporte_restaurante_screen.dart';
import 'package:frontend/screens/admin/admin_restaurante/reportes_restaurante_screen.dart';

class AdminRestauranteDashboard extends StatefulWidget {
  const AdminRestauranteDashboard({super.key});

  @override
  State<AdminRestauranteDashboard> createState() =>
      _AdminRestauranteDashboardState();
}

class _AdminRestauranteDashboardState extends State<AdminRestauranteDashboard> {
  int _selectedIndex = 0;
  bool _isLoadingStatus = true;
  bool _needsOnboarding = false;
  PerfilRestauranteModel? _restaurante;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data.isNotEmpty) {
          _restaurante = PerfilRestauranteModel.fromJson(data.first);
          if (_restaurante!.fotoPortada == null || 
              _restaurante!.fotoPortada!.isEmpty || 
              _restaurante!.fotoPortada == 'null') {
            _needsOnboarding = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  // ── índice 0 = nueva pantalla resumen ─────────────────────
  // ── índice 1 = Perfil (desplazado desde 0) ────────────────
  // ── índices 2..8 = resto desplazados +1 ───────────────────
  final List<Widget> _screens = [
    const DashboardResumenScreen(),
    const PerfilRestauranteScreen(),
    const GestionMesasScreen(),
    const GestionMenusScreen(),
    const GestionReservasScreen(),
    const GestionResenasScreen(),
    const SoporteRestauranteScreen(),
  ];

  static const _sections = [
    SidebarSection(
      title: 'NEGOCIO',
      items: [
        SidebarItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          codigo: 'menu_dashboard',
          index: 0,
        ),
        SidebarItem(
          icon: Icons.restaurant_outlined,
          label: 'Perfil',
          codigo: 'menu_perfil_restaurante',
          index: 1,
        ),
        SidebarItem(
          icon: Icons.table_restaurant_outlined,
          label: 'Mesas',
          codigo: 'menu_mesas',
          index: 2,
        ),
        SidebarItem(
          icon: Icons.menu_book_outlined,
          label: 'Menús',
          codigo: 'menu_menus',
          index: 3,
        ),
      ],
    ),
    SidebarSection(
      title: 'OPERACIÓN',
      items: [
        SidebarItem(
          icon: Icons.calendar_month_outlined,
          label: 'Reservas',
          codigo: 'menu_reservas',
          index: 4,
        ),
        SidebarItem(
          icon: Icons.star_outline,
          label: 'Reseñas',
          codigo: 'menu_resenas',
          index: 5,
        ),
        SidebarItem(
          icon: Icons.support_agent_outlined,
          label: 'Soporte',
          codigo: 'menu_soporte',
          index: 6,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F2F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39))),
      );
    }

    if (_needsOnboarding && _restaurante != null) {
      return OnboardingRestauranteScreen(
        restaurante: _restaurante!,
        onCompleted: () => setState(() => _needsOnboarding = false),
      );
    }

    final auth = AuthScope.of(context);
    final nombre = auth.displayName ?? 'Restaurantero';
    final correo = auth.email ?? 'restaurante@mesachapaca.com';

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
      rolLabel: 'Admin Restaurante',
      body: _screens[_selectedIndex],
    );
  }
}
