import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: _C.bgBody,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BentoSidebar(
            selectedIndex: selectedIndex,
            sections: sections,
            onItemSelected: onItemSelected,
            onLogout: onLogout,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 16),
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
          ),
        ],
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(_C.radiusCard),
        boxShadow: _C.shadowFloat,
      ),
      padding: const EdgeInsets.only(top: 22, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2547), Color(0xFF6E1E39)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color:      Color(0x406E1E39),
                        blurRadius: 16,
                        offset:     Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mesa Chapaca',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D0A14),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'OPERACIONES',
                      style: GoogleFonts.manrope(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: const Color(0xFF6E1E39),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
                    child: Text(
                      section.title,
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: const Color(0xFFA39C98),
                      ),
                    ),
                  ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1, color: Color(0xFFEEECEB)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _LogoutNavItem(onLogout: onLogout),
          ),
        ],
      ),
    );
  }
}

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
    final active  = widget.isSelected;
    final hovered = _hovered && !active;

    final Color iconColor = active ? Colors.white : (hovered ? _C.brandMain : _C.textMuted);
    final Color textColor = active ? Colors.white : (hovered ? _C.brandMain : _C.textDark);
    final FontWeight fw   = active ? FontWeight.w700 : (hovered ? FontWeight.w700 : FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(hovered ? 4.0 : 0.0, 0.0, 0.0),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hovered ? const Color(0xFFFCF4F7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(_C.radiusBtn),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.item.icon, size: 18, color: Colors.transparent),
                      const SizedBox(width: 10),
                      Text(widget.item.label, style: const TextStyle(fontSize: 14.0, color: Colors.transparent)),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: active ? 1.0 : 0.0,
                    curve: Curves.easeOut,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_C.radiusBtn),
                        gradient: const LinearGradient(
                          colors: [_C.brandMain, _C.brandDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x336E1E39),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        AnimatedTheme(
                          duration: const Duration(milliseconds: 200),
                          data: ThemeData(iconTheme: IconThemeData(color: iconColor)),
                          child: Icon(widget.item.icon, size: 18),
                        ),
                        const SizedBox(width: 10),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          style: GoogleFonts.manrope(
                            fontSize: 14.0,
                            fontWeight: fw,
                            color: textColor,
                          ),
                          child: Text(widget.item.label),
                        ),
                      ],
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

class _LogoutNavItem extends StatefulWidget {
  final VoidCallback onLogout;
  const _LogoutNavItem({required this.onLogout});

  @override
  State<_LogoutNavItem> createState() => _LogoutNavItemState();
}

class _LogoutNavItemState extends State<_LogoutNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color fgColor = _hovered ? _C.errorRed : _C.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onLogout,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            // Aquí usamos _hovered en lugar de hovered
            transform: Matrix4.translationValues(_hovered ? 2.0 : 0.0, 0.0, 0.0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered ? _C.errorRed.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(_C.radiusBtn),
            ),
            child: Row(
              children: [
                AnimatedTheme(
                  duration: const Duration(milliseconds: 200),
                  data: ThemeData(iconTheme: IconThemeData(color: fgColor)),
                  child: const Icon(Icons.logout_rounded, size: 18),
                ),
                const SizedBox(width: 10),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
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
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NavCircleBtn(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            badge: true,
          ),
          const SizedBox(width: 12),
          _ProfileCapsule(
            nombreUsuario: nombreUsuario,
            correoUsuario: correoUsuario,
            rolLabel: rolLabel,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ProfileCapsule extends StatelessWidget {
  final String nombreUsuario;
  final String correoUsuario;
  final String rolLabel;
  final VoidCallback onLogout;

  const _ProfileCapsule({
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials = nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'A';

    return PopupMenuButton<String>(
      offset: const Offset(0, 54),
      tooltip: '',
      color: _C.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                correoUsuario,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: _C.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEEECEB)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 16, color: _C.errorRed),
              const SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _C.errorRed,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(_C.radiusPill),
          boxShadow: _C.shadowFloat,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _C.goldMain,
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: _C.textDark,
                    ),
                  ),
                  Text(
                    rolLabel,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _C.textLight),
          ],
        ),
      ),
    );
  }
}

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFEFEDEC) : _C.surface,
            shape: BoxShape.circle,
            boxShadow: _C.shadowFloat,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(widget.icon, size: 18, color: _C.textMuted),
              if (widget.badge)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _C.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}