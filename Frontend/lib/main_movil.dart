import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'movil/providers/auth_provider.dart';
import 'movil/screens/root_screen.dart';

/// Punto de entrada exclusivo para la Aplicación Móvil de Usuarios.
/// Ejecutar en navegador: `flutter run -d chrome -t lib/main_movil.dart`
/// Ejecutar en Android/PC: `flutter run -t lib/main_movil.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = AuthProvider();
  await auth.initialize();
  await auth.restaurarSesion();
  runApp(App(
    authProvider: auth,
    initialScreen: const RootScreen(),
  ));
}
