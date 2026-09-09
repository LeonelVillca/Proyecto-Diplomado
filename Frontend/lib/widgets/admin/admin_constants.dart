part of 'admin_shell.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String codigo;
  final int index;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.codigo,
    required this.index,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;

  const SidebarSection({required this.title, required this.items});
}

abstract class _C {
  static const bgBody   = Color(0xFFF0F2F5);
  static const surface  = Color(0xFFFFFFFF);

  static const brandMain = Color(0xFF6E1E39);
  static const brandDark = Color(0xFF2D0A14);
  static const goldMain  = Color(0xFFC9974F);

  static const textDark  = Color(0xFF1E1B1A);
  static const textMuted = Color(0xFF6B635E);
  static const textLight = Color(0xFFA39C98);

  static const errorRed  = Color(0xFFE74C3C);

  static const shadowFloat = [
    BoxShadow(
      color:       Color(0x0F1E293B),
      blurRadius:  24,
      offset:      Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  static const double radiusCard    = 20.0;
  static const double radiusBtn     = 12.0;
  static const double radiusPill    = 50.0;
}
