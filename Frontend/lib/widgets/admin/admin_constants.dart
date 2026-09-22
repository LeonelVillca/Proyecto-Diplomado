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
  static const bgBody   = Color(0xFFFAF5EC);
  static const surface  = Color(0xFFFFFFFF);

  static const brandMain = Color(0xFFBE4B24);
  static const brandDark = Color(0xFF9E3A18);
  static const goldMain  = Color(0xFFC08A2D);

  static const textDark  = Color(0xFF26201A);
  static const textMuted = Color(0xFF6F6259);
  static const textLight = Color(0xFFA99D91);

  static const errorRed  = Color(0xFFC0341B);

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
