import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/favorites_controller.dart';
import 'package:frontend/screens/movil/shell/root_screen.dart';
import 'package:frontend/screens/admin/public/landing_screen.dart';
import 'package:frontend/screens/admin/auth/crear_contrasena_screen.dart';

/// Punto de entrada inteligente que decide qué interfaz mostrar.
class ResponsiveEntryPoint extends StatelessWidget {
  const ResponsiveEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Si estamos en Web pura o si la pantalla es de tamaño Tablet/PC
    if (kIsWeb || width > 800) {
      return const AdminLandingScreen();
    }
    // Si es un celular nativo
    return const RootScreen();
  }
}

/// Configuración principal de la aplicación (MaterialApp).
class App extends StatelessWidget {
  const App({
    super.key,
    this.authController,
    this.favoritesController,
    this.initialScreen,
  });

  /// Proveedor de autenticación (se inyecta desde `main`).
  final AuthController? authController;

  /// Guarda de favoritos (opcional para tests).
  final FavoritesController? favoritesController;

  /// Pantalla inicial explícita (opcional, aunque ya no la usaremos).
  final Widget? initialScreen;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authController: authController ?? AuthController(),
      child: FavoritesScope(
        favoritesController: favoritesController ?? FavoritesController(),
        child: MaterialApp(
          title: 'Mesa Chapaca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: initialScreen ?? const ResponsiveEntryPoint(),
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
    );
  }
}