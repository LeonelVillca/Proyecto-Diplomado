import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/favorites_controller.dart';
import 'package:frontend/screens/admin/public/landing_screen.dart';
import 'package:frontend/screens/admin/auth/crear_contrasena_screen.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:frontend/app.dart'; // Para reutilizar AppScopeManager

class ResponsiveEntryPointWeb extends StatelessWidget {
  const ResponsiveEntryPointWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    
    // Si ya tiene sesión web activa, redirigir directo al dashboard
    if (auth.token != null) {
      if (auth.hasRole('admin_sistema')) {
        return const AdminSistemaDashboard();
      } else if (auth.hasRole('admin_restaurante')) {
        return const AdminRestauranteDashboard();
      }
    }
    
    // Si no está logueado o no tiene rol de admin, mostrar Landing pública
    return const AdminLandingScreen();
  }
}

class AppWeb extends StatelessWidget {
  const AppWeb({
    super.key,
    this.authController,
    this.favoritesController,
  });

  final AuthController? authController;
  final FavoritesController? favoritesController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authController: authController ?? AuthController(),
      child: FavoritesScope(
        favoritesController: favoritesController ?? FavoritesController(),
        child: AppScopeManager(
          child: MaterialApp(
            title: 'Mesa Chapaca - Web Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const ResponsiveEntryPointWeb(),
            onGenerateRoute: (settings) {
              if (settings.name != null && settings.name!.startsWith('/crear-contrasena')) {
                final uri = Uri.parse(settings.name!);
                final token = uri.queryParameters['token'];
                return MaterialPageRoute(
                  builder: (context) => CrearContrasenaScreen(token: token),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
