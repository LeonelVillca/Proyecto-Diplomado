import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:frontend/app.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = AuthController();
  await auth.initialize();
  // Restaura la sesión guardada (JWT en secure storage): si el token sigue
  // siendo válido contra el backend se entra directo, si no vuelve al login.
  await auth.restaurarSesion();
  runApp(App(authController: auth));
}
