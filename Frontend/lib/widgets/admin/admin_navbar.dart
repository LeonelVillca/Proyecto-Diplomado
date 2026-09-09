part of 'admin_shell.dart';

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
            icon: Icons.notifications_outlined,
            onTap: () {},
            badge: false,
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: const Color(0xFFEEECEB)),
          const SizedBox(width: 16),
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

class _ProfileCapsule extends StatefulWidget {
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
  State<_ProfileCapsule> createState() => _ProfileCapsuleState();
}

class _ProfileCapsuleState extends State<_ProfileCapsule> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.nombreUsuario.isNotEmpty ? widget.nombreUsuario[0].toUpperCase() : 'A';
    final firstName = widget.nombreUsuario.split(' ').first;
    final formattedName = firstName.isNotEmpty 
        ? '${firstName[0].toUpperCase()}${firstName.substring(1).toLowerCase()}' 
        : '';

    const primaryTeal = Color(0xFF008080);

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        tooltip: '',
        color: _C.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (v) {
          if (v == 'logout') widget.onLogout();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _C.brandMain,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombreUsuario,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _C.brandDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sesión activa',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _C.textMuted,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEEECEB)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.bgBody,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 20, color: _C.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROL',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _C.textLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              widget.rolLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _C.bgBody,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined, size: 20, color: _C.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CORREO',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _C.textLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              widget.correoUsuario,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEEECEB)),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            value: 'logout',
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, size: 20, color: _C.errorRed),
                const SizedBox(width: 12),
                Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFFF9FAFB) : Colors.transparent,
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(color: _hovered ? const Color(0xFFE5E7EB) : Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1F2937),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.rolLabel.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryTeal.withOpacity(0.10),
                    border: Border.all(
                      color: primaryTeal.withOpacity(0.20),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      color: primaryTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
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
            color: _hovered ? const Color(0xFFEFEDEC) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(widget.icon, size: 24, color: _C.textMuted),
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
