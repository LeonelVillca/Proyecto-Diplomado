import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({this.onRegister, super.key});
  final VoidCallback? onRegister;

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = LandingLayout.horizontalPadding(width);
    final compact = width < LandingLayout.tablet;
    final brand = _FooterBrand(onRegister: onRegister);
    final contact = _FooterContact(onOpen: _open);
    
    return ColoredBox(
      color: LandingPalette.wineDeep,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            compact ? 56 : 72,
            horizontal,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LandingLayout.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        brand,
                        const SizedBox(height: 40),
                        contact,
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: brand),
                        const SizedBox(width: 64),
                        Expanded(flex: 4, child: contact),
                      ],
                    ),
                  const SizedBox(height: 56),
                  const Divider(color: Color(0x44FFFFFF)),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    spacing: 24,
                    children: [
                      Text(
                        '© 2026 Mesa Chapaca. Todos los derechos reservados.',
                        style: LandingType.bodyText(
                          size: 14,
                          color: const Color(0xFFCDBDC3),
                        ),
                      ),
                      Text(
                        'Hecho en Tarija, Bolivia.',
                        style: LandingType.bodyText(
                          size: 14,
                          color: const Color(0xFFCDBDC3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand({required this.onRegister});
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Una mejor mesa empieza con una mejor coordinación.',
            style: LandingType.heading(size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Mesa Chapaca conecta restaurantes y comensales con una experiencia de reserva clara, cercana y hecha para Tarija.',
            style: LandingType.bodyText(
              size: 17,
              color: const Color(0xFFD8CAD0),
            ),
          ),
        ),
        if (onRegister != null) ...[
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onRegister,
            style: FilledButton.styleFrom(
              backgroundColor: LandingPalette.gold,
              foregroundColor: LandingPalette.ink,
              minimumSize: const Size(48, 52),
              textStyle: LandingType.bodyText(
                size: 16,
                color: LandingPalette.ink,
                weight: FontWeight.w700,
              ),
            ),
            child: const Text('Registrar mi restaurante'),
          ),
        ],
      ],
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact({required this.onOpen});
  final Future<void> Function(Uri uri) onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Información de contacto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hablemos de tu restaurante',
            style: LandingType.bodyText(
              size: 18,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _ContactButton(
            icon: Icons.email_outlined,
            label: 'contacto@mesachapaca.bo',
            onPressed: () =>
                onOpen(Uri.parse('mailto:contacto@mesachapaca.bo')),
          ),
          const SizedBox(height: 8),
          _ContactButton(
            icon: Icons.location_on_outlined,
            label: 'Tarija, Bolivia',
            onPressed: () => onOpen(
              Uri.parse('https://maps.google.com/?q=Tarija%2C+Bolivia'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF7EEF1),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        alignment: Alignment.centerLeft,
        textStyle: LandingType.bodyText(size: 16, color: Colors.white),
      ),
      icon: Icon(icon, color: LandingPalette.gold),
      label: Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
    );
  }
}
