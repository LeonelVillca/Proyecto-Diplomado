import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// Configuración principal de la aplicación (MaterialApp).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frontend',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
    );
  }
}