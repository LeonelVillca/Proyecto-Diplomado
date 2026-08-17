import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'movil/providers/auth_provider.dart';
import 'admin/screens/landing_screen.dart';

/// Punto de entrada exclusivo para el Portal Web Administrativo y Landing Page.
/// Ejecutar con: `flutter run -d chrome -t lib/main_admin.dart`
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
    initialScreen: const AdminLandingScreen(),
  ));
}
