import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:frontend/app_web.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = AuthController();
  await auth.initialize();
  
  // Restaura la sesión guardada (JWT en secure storage)
  await auth.restaurarSesion();
  
  runApp(AppWeb(authController: auth));
}
