import 'package:flutter/material.dart';

import 'movil/core/theme.dart';
import 'movil/providers/auth_provider.dart';
import 'movil/providers/favorites_provider.dart';
import 'movil/screens/root_screen.dart';

/// Configuración principal de la aplicación (MaterialApp).
class App extends StatelessWidget {
  const App({super.key, this.authProvider, this.favoritesStore});

  /// Proveedor de autenticación (se inyecta desde `main`).
  final AuthProvider? authProvider;

  /// Guarda de favoritos (opcional para tests).
  final FavoritesStore? favoritesStore;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authProvider: authProvider ?? AuthProvider(),
      child: FavoritesScope(
        favoritesStore: favoritesStore ?? FavoritesStore(),
        child: MaterialApp(
          title: 'Mesa Chapaca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const RootScreen(),
        ),
      ),
    );
  }
}