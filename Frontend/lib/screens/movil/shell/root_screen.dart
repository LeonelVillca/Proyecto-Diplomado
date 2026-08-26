import 'package:flutter/material.dart';

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';

/// Pantalla de arranque: elige entre el login y el contenido principal
/// según el estado de autenticación. Se reconstruye sola cuando cambia
/// la sesión (el [AuthScope] es un `InheritedNotifier`).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  RestauranteController? _restauranteController;

  @override
  void dispose() {
    _restauranteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    
    if (!auth.isAuthenticated) {
      _restauranteController?.dispose();
      _restauranteController = null;
      return const LoginScreen();
    }

    if (_restauranteController == null) {
      _restauranteController = RestauranteController(auth.token);
    }

    return RestauranteScope(
      controller: _restauranteController!,
      child: const MainShell(),
    );
  }
}