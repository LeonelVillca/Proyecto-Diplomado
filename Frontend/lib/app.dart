import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/shell/root_screen.dart';
// Descomentar para modo mixto/web
// import 'package:frontend/screens/admin/public/landing_screen.dart';
// import 'package:frontend/screens/admin/auth/crear_contrasena_screen.dart';

class AppScopeManager extends StatefulWidget {
  final Widget child;
  const AppScopeManager({super.key, required this.child});
  @override
  State<AppScopeManager> createState() => _AppScopeManagerState();
}

class _AppScopeManagerState extends State<AppScopeManager> {
  RestauranteController? _restauranteController;
  String? _lastToken;

  @override
  void dispose() {
    _restauranteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (_restauranteController == null || _lastToken != auth.token) {
      _lastToken = auth.token;
      _restauranteController = RestauranteController(auth.token);
    }

    return RestauranteScope(
      controller: _restauranteController!,
      child: widget.child,
    );
  }
}

/// Punto de entrada inteligente que decide qué interfaz mostrar.
class ResponsiveEntryPoint extends StatelessWidget {
  const ResponsiveEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    // Para compilar la app móvil nativa, forzamos RootScreen y comentamos la parte web
    // para evitar errores de compilación con librerías exclusivas de web (ej. dart:html)
    return const RootScreen();
  }
}

/// Configuración principal de la aplicación (MaterialApp).
class App extends StatelessWidget {
  const App({super.key, this.authController, this.initialScreen});

  /// Proveedor de autenticación (se inyecta desde `main`).
  final AuthController? authController;

  /// Pantalla inicial explícita (opcional, aunque ya no la usaremos).
  final Widget? initialScreen;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authController: authController ?? AuthController(),
      child: AppScopeManager(
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Mesa Chapaca',
            debugShowCheckedModeBanner: false,
            theme: AuthScope.of(context).isAuthenticated
                ? ConsumerTheme.light
                : AppTheme.light,
            home: initialScreen ?? const ResponsiveEntryPoint(),
            onGenerateRoute: (settings) {
              // if (settings.name != null && settings.name!.startsWith('/crear-contrasena')) {
              //   final uri = Uri.parse(settings.name!);
              //   final token = uri.queryParameters['token'];
              //   return MaterialPageRoute(
              //     builder: (context) => CrearContrasenaScreen(token: token),
              //   );
              // }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
