import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Secciones accesibles desde la barra de navegación inferior.
enum HomeTab {
  inicio('Inicio', LucideIcons.house),
  ubicacion('Ubicación', LucideIcons.map),
  reservas('Reservas', LucideIcons.calendarCheck),
  usuarios('Perfil', LucideIcons.user);

  const HomeTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
