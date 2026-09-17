import 'package:flutter/material.dart';

/// Secciones accesibles desde la barra de navegación inferior.
enum HomeTab {
  inicio('Inicio', Icons.home_rounded),
  reservas('Reservas', Icons.calendar_month_rounded),
  ubicacion('Ubicación', Icons.place_rounded),
  usuarios('Usuarios', Icons.person_rounded);

  const HomeTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
