import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/public/landing_screen.dart';
import 'package:frontend/screens/admin/auth/crear_contrasena_screen.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:frontend/app.dart'; // Para reutilizar AppScopeManager
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/widgets/shared/session_navigation.dart';

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
  const AppWeb({super.key, this.authController});

  final AuthController? authController;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authController: authController ?? AuthController(),
      child: AppScopeManager(
        child: SessionNavigation(
          loginBuilder: (_) => const AdminLoginScreen(),
          builder: (context, navigatorKey) => MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Mesa Chapaca | Reservas para restaurantes de Tarija',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const ResponsiveEntryPointWeb(),
            onGenerateRoute: (settings) {
              if (settings.name != null &&
                  settings.name!.startsWith('/crear-contrasena')) {
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
