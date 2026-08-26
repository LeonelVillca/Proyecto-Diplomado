import 'package:flutter/material.dart';

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';

/// Pantalla de arranque: elige entre el login y el contenido principal
/// según el estado de autenticación. Se reconstruye sola cuando cambia
/// la sesión (el [AuthScope] es un `InheritedNotifier`).
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}