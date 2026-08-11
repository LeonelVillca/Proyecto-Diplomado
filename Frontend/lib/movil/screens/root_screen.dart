import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'login/login_screen.dart';
import 'main/main_shell.dart';

/// Pantalla de arranque: elige entre el login y el contenido principal
/// según el estado de autenticación. Se reconstruye sola cuando cambia
/// la sesión (el [AuthScope] es un `InheritedNotifier`).
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return auth.isAuthenticated ? const MainShell() : const LoginScreen();
  }
}