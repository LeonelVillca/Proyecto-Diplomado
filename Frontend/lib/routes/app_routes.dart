import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

/// Definición central de las rutas de la aplicación.
abstract final class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
  };
}