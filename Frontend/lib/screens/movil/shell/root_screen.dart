import 'package:flutter/material.dart';

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'package:frontend/screens/movil/onboarding/onboarding_screen.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';

/// Pantalla de arranque: elige entre el onboarding y el contenido principal
/// según el estado de autenticación. Se reconstruye sola cuando cambia
/// la sesión (el [AuthScope] es un `InheritedNotifier`).
///
/// Flujo: OnboardingScreen → LoginScreen → MainShell
/// (OnboardingScreen navega sola hacia LoginScreen al finalizar)
class RootScreen extends StatefulWidget {
  const RootScreen({super.key, this.showOnboarding = true});

  final bool showOnboarding;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late bool _showOnboarding = widget.showOnboarding;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.isAuthenticated) {
      return const MainShell();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showOnboarding
          ? OnboardingScreen(
              key: const ValueKey('onboarding'),
              onFinish: () => setState(() => _showOnboarding = false),
            )
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
