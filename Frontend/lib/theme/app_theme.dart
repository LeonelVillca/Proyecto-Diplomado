import 'package:flutter/material.dart';

/// Tema global de la aplicación: paleta de colores y estilos.
abstract final class AppTheme {
  AppTheme._();

  static const Color seedColor = Colors.deepPurple;

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
    ),
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
  );
}