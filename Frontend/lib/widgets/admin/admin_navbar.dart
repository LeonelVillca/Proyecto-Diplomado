part of 'admin_shell.dart';

class _BentoNavbar extends StatelessWidget {
  const _BentoNavbar({
    required this.currentSection,
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolLabel,
    required this.onLogout,
  });

  final String currentSection;
  final String nombreUsuario;
  final String correoUsuario;
  final String rolLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: const BoxDecoration(
        color: Color(0xD9FAF5EC),
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Operaciones', style: TextStyle(color: AdminTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(LucideIcons.chevronRight, size: 16, color: AdminTheme.textMuted),
                ),
                Text(currentSection, style: const TextStyle(color: AdminTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Tooltip(
            message: 'Notificaciones',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.bell, size: 19),
              style: IconButton.styleFrom(
                foregroundColor: AdminTheme.textMuted,
                backgroundColor: AdminTheme.surface,
                side: const BorderSide(color: AdminTheme.border),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
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
  const _ProfileCapsule({
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.rolLabel,
    required this.onLogout,
  });

  final String nombreUsuario;
  final String correoUsuario;
  final String rolLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = nombreUsuario.trim().isEmpty ? 'Administrador' : nombreUsuario.trim();
    final initials = name.split(RegExp(r'\s+')).take(2).map((part) => part[0]).join().toUpperCase();
    return PopupMenuButton<String>(
      tooltip: 'Abrir menú de usuario',
      offset: const Offset(0, 12),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 286),
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      color: AdminTheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: AdminTheme.border),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 0,
          child: SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AdminTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Fraunces',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.subtitleStyle.copyWith(fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(correoUsuario, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: AdminTheme.accentSoft, borderRadius: AdminTheme.pillRadius),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 14, color: AdminTheme.accentColor),
                        const SizedBox(width: 7),
                        Text(rolLabel.toUpperCase(), style: const TextStyle(color: AdminTheme.accentColor, fontSize: 10.5, letterSpacing: .7, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Divider(height: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          height: 54,
          padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AdminTheme.errorSoft, borderRadius: AdminTheme.pillRadius),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Icon(LucideIcons.logOut, color: AdminTheme.error, size: 17),
                        SizedBox(width: 9),
                        Text('Cerrar sesión', style: TextStyle(color: AdminTheme.error, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 7, 10, 7),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          border: Border.all(color: AdminTheme.border),
          borderRadius: AdminTheme.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AdminTheme.accentColor, shape: BoxShape.circle),
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 134),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
                  Text(rolLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AdminTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 17, color: AdminTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
