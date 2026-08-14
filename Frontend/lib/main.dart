import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'movil/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = AuthProvider();
  await auth.initialize();
  // Restaura la sesión guardada (JWT en secure storage): si el token sigue
  // siendo válido contra el backend se entra directo, si no vuelve al login.
  await auth.restaurarSesion();
  runApp(App(authProvider: auth));
}
