import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/admin/theme_admin.dart';

part 'admin_constants.dart';
part 'admin_sidebar.dart';
part 'admin_navbar.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 1020;
    final currentSection = sections
        .expand((section) => section.items)
        .map((item) => item.index == selectedIndex ? item.label : '')
        .firstWhere((label) => label.isNotEmpty, orElse: () => 'Operaciones');
    final sidebar = _BentoSidebar(
      selectedIndex: selectedIndex,
      sections: sections,
      isMobile: !isDesktop,
      onItemSelected: (index) {
        onItemSelected(index);
        if (!isDesktop) Navigator.of(context).pop();
      },
      onLogout: onLogout,
    );

    return Theme(
      data: AdminTheme.webTheme,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: isDesktop
            ? null
            : AppBar(
                title: Text('Mesa Chapaca', style: AdminTheme.titleStyle.copyWith(fontSize: 20)),
                iconTheme: const IconThemeData(color: AdminTheme.textDark),
                actions: [
                  _ProfileCapsule(
                    nombreUsuario: nombreUsuario,
                    correoUsuario: correoUsuario,
                    rolLabel: rolLabel,
                    onLogout: onLogout,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        drawer: isDesktop
            ? null
            : Drawer(
                backgroundColor: AdminTheme.sidebar,
                child: sidebar,
              ),
        body: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sidebar,
                  Expanded(
                    child: Column(
                      children: [
                        _BentoNavbar(
                          currentSection: currentSection,
                          nombreUsuario: nombreUsuario,
                          correoUsuario: correoUsuario,
                          rolLabel: rolLabel,
                          onLogout: onLogout,
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1240),
                              child: body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                child: body,
              ),
      ),
    );
  }
}
