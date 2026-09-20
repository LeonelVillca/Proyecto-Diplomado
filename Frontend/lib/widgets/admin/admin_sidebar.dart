part of 'admin_shell.dart';

class _BentoSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<SidebarSection> sections;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final bool isMobile;

  const _BentoSidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onItemSelected,
    required this.onLogout,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(_C.radiusCard),
        boxShadow: isMobile ? null : _C.shadowFloat,
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon_app.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mesa Chapaca',
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B1A),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        'OPERACIONES',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: _C.brandMain,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
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
    final hovered = _hovered;

    final Color bgColor = active ? _C.brandMain : (hovered ? const Color(0xFFF9FAFB) : Colors.transparent);
    final Color iconColor = active ? Colors.white : (hovered ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF));
    final Color textColor = active ? Colors.white : (hovered ? const Color(0xFF111827) : const Color(0xFF6B7280));
    final FontWeight fw = active ? FontWeight.w700 : FontWeight.w400;
    
    final double scale = (active || hovered) ? 1.05 : 1.0;
    
    final List<BoxShadow>? shadows = active 
        ? [BoxShadow(color: _C.brandMain.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))]
        : (hovered ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))] : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: shadows,
            ),
            child: Row(
              children: [
                AnimatedTheme(
                  duration: const Duration(milliseconds: 200),
                  data: ThemeData(iconTheme: IconThemeData(color: iconColor)),
                  child: Icon(widget.item.icon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.inter(
                      fontSize: 16.0,
                      fontWeight: fw,
                      color: textColor,
                    ),
                    child: Text(widget.item.label),
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
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                    child: const Text(
                      'Cerrar todas las sesiones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

