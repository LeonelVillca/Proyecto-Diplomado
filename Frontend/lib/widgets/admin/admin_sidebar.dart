part of 'admin_shell.dart';

class _BentoSidebar extends StatelessWidget {
  const _BentoSidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onItemSelected,
    required this.onLogout,
    required this.isMobile,
    required this.restaurantName,
    required this.nombreUsuario,
    required this.rolLabel,
  });

  final int selectedIndex;
  final List<SidebarSection> sections;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final bool isMobile;
  final String? restaurantName;
  final String nombreUsuario;
  final String rolLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebar,
        border: Border(right: BorderSide(color: AdminTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarBrand(),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0EAE0), height: 1),
          const SizedBox(height: 12),
          if (restaurantName != null && restaurantName!.trim().isNotEmpty) ...[
            _SidebarRestaurantCard(name: restaurantName!),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 7),
                    child: Text(
                      section.title.toUpperCase(),
                      style: const TextStyle(
                        color: AdminTheme.sidebarText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  for (final item in section.items)
                    _BentoNavItem(
                      item: item,
                      isSelected: selectedIndex == item.index,
                      onTap: () => onItemSelected(item.index),
                    ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFFF0EAE0), height: 1),
          const SizedBox(height: 8),
          _SidebarUser(name: nombreUsuario, role: rolLabel),
          _LogoutNavItem(onLogout: onLogout),
        ],
      ),
    );
  }
}

class _SidebarRestaurantCard extends StatelessWidget {
  const _SidebarRestaurantCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFAF6EE),
      border: Border.all(color: const Color(0xFFF0EAE0)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AdminTheme.accentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name.trim().substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Fraunces',
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 13,
                  color: AdminTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Restaurante',
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 11,
                  color: AdminTheme.sidebarText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SidebarUser extends StatelessWidget {
  const _SidebarUser({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final display = name.trim().isEmpty ? 'Administrador' : name.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AdminTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              display.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminTheme.sidebarText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AdminTheme.textDark,
              borderRadius: BorderRadius.all(Radius.circular(11)),
            ),
            child: const Icon(
              LucideIcons.utensils,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa Chapaca',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    color: AdminTheme.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'OPERACIONES',
                  style: TextStyle(
                    color: AdminTheme.sidebarText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.62,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoNavItem extends StatefulWidget {
  const _BentoNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BentoNavItem> createState() => _BentoNavItemState();
}

class _BentoNavItemState extends State<_BentoNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFFAF5EC),
        focusColor: const Color(0xFFFAF5EC),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0x1A55684B)
                : _hovered
                ? const Color(0xFFFAF5EC)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered && !widget.isSelected
                  ? const Color(0xFFF0EAE0)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 19,
                color: widget.isSelected
                    ? AdminTheme.sidebarActiveText
                    : _hovered
                    ? AdminTheme.textDark
                    : AdminTheme.sidebarText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AdminTheme.sidebarActiveText
                        : _hovered
                        ? AdminTheme.textDark
                        : AdminTheme.sidebarText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(padding: const EdgeInsets.only(bottom: 2), child: content),
    );
  }
}

class _LogoutNavItem extends StatelessWidget {
  const _LogoutNavItem({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFFAF5EC),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 19,
                color: AdminTheme.sidebarText,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: AdminTheme.sidebarText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
