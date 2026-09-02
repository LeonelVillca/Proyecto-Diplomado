import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';

/// Barra de navegación flotante estilo "píldora centrada".
///
/// El indicador del ítem activo es una cápsula dorada que NO toca
/// los bordes del menú — queda contenida en el centro de cada celda.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onSelected});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  // Paleta oficial Mesa Chapaca
  static const _bg     = AppColors.card;      // blanco roto
  static const _accent = AppColors.wine;      // vino activo
  static const _inact  = AppColors.inkSoft;   // gris inactivo

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final tab in HomeTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelected(tab),
                    accent: _accent,
                    inact: _inact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.inact,
  });

  final HomeTab tab;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color inact;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : inact;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // La píldora tiene ancho fijo para NO tocar los bordes del menú
          width: selected ? 56 : 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(tab.icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}