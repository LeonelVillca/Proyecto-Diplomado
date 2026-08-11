import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/movil/core/theme.dart';
import 'package:frontend/movil/providers/auth_provider.dart';
import 'package:frontend/movil/providers/favorites_provider.dart';
import 'package:frontend/movil/screens/main/main_shell.dart';
import 'package:frontend/movil/widgets/navigation/app_bottom_nav.dart';

void main() {
  testWidgets('Main shell renderiza las pestañas y el inicio',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      AuthScope(
        authProvider: AuthProvider(),
        child: FavoritesScope(
          favoritesStore: FavoritesStore(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Las cinco pestañas de la barra flotante.
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reservas'), findsWidgets);
    expect(find.text('Favoritos'), findsWidgets);
    expect(find.text('Ubicación'), findsWidgets);
    expect(find.text('Usuarios'), findsWidgets);

    // Contenido del Home.
    expect(find.text('¡Hola, Chapaco! 👋'), findsOneWidget);
    expect(find.text('Tendencia en Tarija 🔥'), findsOneWidget);
    expect(find.text('Vino y Luna'), findsWidgets);
  });

  testWidgets('Favorito se puede alternar y visita la pestaña Favoritos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      AuthScope(
        authProvider: AuthProvider(),
        child: FavoritesScope(
          favoritesStore: FavoritesStore(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Cambia a la pestaña Favoritos.
    await tester.tap(find.text('Favoritos').first);
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
  });

  testWidgets('Sin overflow en pantalla de teléfono en todas las pestañas',
      (WidgetTester tester) async {
    // Simula un móvil de 360 dp de ancho (físico 1080x2280 a densidad 3).
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AuthScope(
        authProvider: AuthProvider(),
        child: FavoritesScope(
          favoritesStore: FavoritesStore(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in [
      'Inicio',
      'Reservas',
      'Favoritos',
      'Ubicación',
      'Usuarios'
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}