part of 'admin_shell.dart';

class _BentoSidebar extends StatelessWidget {
  const _BentoSidebar({
    required this.selectedIndex,
    required this.sections,
    required this.onItemSelected,
    required this.onLogout,
    required this.isMobile,
  });

  final int selectedIndex;
  final List<SidebarSection> sections;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      color: AdminTheme.sidebar,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SidebarBrand(),
          const SizedBox(height: 12),
          const Divider(color: Color(0x1AFDF4EE), height: 1),
          const SizedBox(height: 12),
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
                        color: Color(0x73FDF4EE),
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
          const Divider(color: Color(0x1AFDF4EE), height: 1),
          const SizedBox(height: 8),
          _LogoutNavItem(onLogout: onLogout),
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
              color: AdminTheme.primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(11)),
            ),
            child: const Icon(LucideIcons.utensils, color: Colors.white, size: 19),
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
                    color: AdminTheme.sidebarActiveText,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'OPERACIONES',
                  style: TextStyle(
                    color: Color(0x8CFDF4EE),
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

class _BentoNavItem extends StatelessWidget {
  const _BentoNavItem({required this.item, required this.isSelected, required this.onTap});

  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0x12FDF4EE),
        focusColor: const Color(0x22FDF4EE),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x38BE4B24) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 19, color: isSelected ? AdminTheme.sidebarActiveText : AdminTheme.sidebarText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AdminTheme.sidebarActiveText : AdminTheme.sidebarText,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (isSelected)
            const Positioned(
              left: -16,
              top: 9,
              bottom: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AdminTheme.primaryColor,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                ),
                child: SizedBox(width: 4),
              ),
            ),
        ],
      ),
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
        hoverColor: const Color(0x14C0341B),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 19, color: Color(0xFFF5B2A5)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Color(0xFFF5B2A5), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
