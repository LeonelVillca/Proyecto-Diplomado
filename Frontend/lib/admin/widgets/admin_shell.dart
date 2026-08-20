import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────
class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;

  const SidebarSection({required this.title, required this.items});
}

// ─────────────────────────────────────────────────────────────
//  TOKENS DE DISEÑO — Mesa Chapaca Bento UI
// ─────────────────────────────────────────────────────────────
abstract class _C {
  // Paleta marca
  static const brand    = Color(0xFF6B1A35);
  static const brandBg  = Color(0xFFF6EEF1);

  // Grises
  static const bg       = Color(0xFFF5F6F8);
  static const surface  = Colors.white;
  static const border   = Color(0xFFEAEBEF);

  // Texto
  static const txDark   = Color(0xFF111827); // slate-900
  static const txMid    = Color(0xFF6B7280); // slate-500
  static const txMuted  = Color(0xFF9CA3AF); // slate-400

  // Sombras
  static const shadowSm = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 2)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 4)),
  ];

  // Font
  static const font = 'Karla';
}

// ─────────────────────────────────────────────────────────────
//  ADMIN SHELL — Layout Maestro Bento
// ─────────────────────────────────────────────────────────────
class AdminShell extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final List<SidebarSection> sections;
  final Widget body;
  final String nombreUsuario;
  final String correoUsuario;
  final String rolLabel;

  const AdminShell({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.sections,
    required this.body,
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sidebar flotante ─────────────────────────
            _BentoSidebar(
              selectedIndex: selectedIndex,
              sections: sections,
              onItemSelected: onItemSelected,
              onLogout: onLogout,
            ),
            const SizedBox(width: 12),
            // ── Área de contenido ─────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BentoNavbar(
                    nombreUsuario: nombreUsuario,
                    correoUsuario: correoUsuario,
                    rolLabel: rolLabel,
                    onLogout: onLogout,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SIDEBAR — Tarjeta flotante con Bento style
// ─────────────────────────────────────────────────────────────
class _BentoSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<SidebarSection> sections;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const _BentoSidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _C.shadowSm,
      ),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.brand, width: 2.2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu_outlined,
                      color: _C.brand,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Mesa Chapaca',
                  style: TextStyle(
                    fontFamily: _C.font,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: _C.txDark,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),

          // ── Secciones ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in sections) ...[
                  // Label de sección
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        fontFamily: _C.font,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _C.txMuted,
                      ),
                    ),
                  ),
                  // Ítems
                  ...section.items.map(
                    (item) => _BentoNavItem(
                      item: item,
                      isSelected: selectedIndex == item.index,
                      onTap: () => onItemSelected(item.index),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Tarjeta inferior ──────────────────────────
          const SizedBox(height: 12),
          _SidebarPromoCard(onLogout: onLogout),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ÍTEM DEL SIDEBAR — Solo barra lateral + color, sin rectángulo
// ─────────────────────────────────────────────────────────────
class _BentoNavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BentoNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BentoNavItem> createState() => _BentoNavItemState();
}

class _BentoNavItemState extends State<_BentoNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final hovered = _hovered && !active;

    final Color iconColor = active
        ? _C.brand
        : hovered
            ? _C.txDark
            : _C.txMid;

    final Color textColor = active
        ? _C.brand
        : hovered
            ? _C.txDark
            : _C.txMid;

    final FontWeight fontWeight =
        active ? FontWeight.w700 : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: hovered
                  ? const Color(0xFFF9FAFB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Contenido del ítem
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          widget.item.icon,
                          key: ValueKey(active),
                          size: 17,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 11),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          fontFamily: _C.font,
                          fontSize: 13.5,
                          fontWeight: fontWeight,
                          color: textColor,
                        ),
                        child: Text(widget.item.label),
                      ),
                    ],
                  ),
                ),
                // Barra indicadora izquierda (solo activo)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: active ? 1.0 : 0.0,
                  child: Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 3.5,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _C.brand,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TARJETA PROMO / LOGOUT en el footer del sidebar
// ─────────────────────────────────────────────────────────────
class _SidebarPromoCard extends StatefulWidget {
  final VoidCallback onLogout;
  const _SidebarPromoCard({required this.onLogout});

  @override
  State<_SidebarPromoCard> createState() => _SidebarPromoCardState();
}

class _SidebarPromoCardState extends State<_SidebarPromoCard> {
  bool _hoverBtn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C1529), Color(0xFF8C2040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined,
              color: Colors.white60, size: 22),
          const SizedBox(height: 10),
          const Text(
            'Panel de Gestión',
            style: TextStyle(
              fontFamily: _C.font,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Mesa Chapaca Admin',
            style: TextStyle(
              fontFamily: _C.font,
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 14),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverBtn = true),
            onExit: (_) => setState(() => _hoverBtn = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onLogout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _hoverBtn
                      ? Colors.white.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 13, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontFamily: _C.font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NAVBAR SUPERIOR — Elementos flotantes sobre fondo gris
// ─────────────────────────────────────────────────────────────
class _BentoNavbar extends StatelessWidget {
  final String nombreUsuario;
  final String correoUsuario;
  final String rolLabel;
  final VoidCallback onLogout;

  const _BentoNavbar({
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'A';

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Búsqueda tipo píldora ─────────────────────
          Flexible(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: _C.shadowSm,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 16, color: _C.txMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          fontFamily: _C.font,
                          fontSize: 13,
                          color: _C.txDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(
                            fontFamily: _C.font,
                            fontSize: 13,
                            color: _C.txMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEBEF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⌘ F',
                        style: TextStyle(
                          fontFamily: _C.font,
                          fontSize: 10,
                          color: _C.txMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ── Botón circular: Mail ──────────────────────
          _NavCircleBtn(
            icon: Icons.mail_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 8),

          // ── Botón circular: Campana ───────────────────
          _NavCircleBtn(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            badge: true,
          ),
          const SizedBox(width: 12),

          // ── Badge/Cápsula del usuario ─────────────────
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            tooltip: '',
            color: _C.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (v) {
              if (v == 'logout') onLogout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombreUsuario,
                      style: const TextStyle(
                        fontFamily: _C.font,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _C.txDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      correoUsuario,
                      style: const TextStyle(
                        fontFamily: _C.font,
                        fontSize: 12,
                        color: _C.txMid,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFEAEBEF)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 16, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontFamily: _C.font,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(99),
                boxShadow: _C.shadowSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: _C.brand,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        fontFamily: _C.font,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreUsuario,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _C.font,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: _C.txDark,
                          ),
                        ),
                        Text(
                          correoUsuario,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _C.font,
                            fontSize: 10.5,
                            color: _C.txMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: _C.txMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTÓN CIRCULAR DE NAVBAR
// ─────────────────────────────────────────────────────────────
class _NavCircleBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _NavCircleBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  State<_NavCircleBtn> createState() => _NavCircleBtnState();
}

class _NavCircleBtnState extends State<_NavCircleBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget iconW = Icon(widget.icon, size: 18, color: _C.txMid);
    if (widget.badge) {
      iconW = Badge(
        backgroundColor: _C.brand,
        smallSize: 6.5,
        child: iconW,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFF0F1F3)
                : _C.surface,
            shape: BoxShape.circle,
            boxShadow: _C.shadowSm,
          ),
          child: Center(child: iconW),
        ),
      ),
    );
  }
}
