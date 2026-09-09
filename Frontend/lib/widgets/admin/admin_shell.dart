import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    final sidebar = _BentoSidebar(
      selectedIndex: selectedIndex,
      sections: sections,
      isMobile: !isDesktop,
      onItemSelected: (i) {
        onItemSelected(i);
        if (!isDesktop) {
          Navigator.of(context).pop(); // Close drawer on selection
        }
      },
      onLogout: onLogout,
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _C.bgBody,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sidebar,
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
    } else {
      return Scaffold(
        backgroundColor: _C.bgBody,
        appBar: AppBar(
          backgroundColor: _C.surface,
          elevation: 0,
          scrolledUnderElevation: 0, // Prevent color change on scroll in M3
          iconTheme: const IconThemeData(color: _C.textDark),
          title: Text(
            'Mesa Chapaca',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D0A14),
            ),
          ),
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
        drawer: Drawer(
          backgroundColor: _C.surface,
          child: sidebar,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: body,
        ),
      );
    }
  }
}



