import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    this.onRegister,
    this.onBenefits,
    this.onHowItWorks,
    this.onProfile,
    this.onRestaurants,
    this.onFaq,
    this.onAccess,
    super.key,
  });

  final VoidCallback? onRegister;
  final VoidCallback? onBenefits;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onProfile;
  final VoidCallback? onRestaurants;
  final VoidCallback? onFaq;
  final VoidCallback? onAccess;

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = LandingLayout.horizontalPadding(width);
    final columns = width < 640 ? 1 : (width < 1020 ? 2 : 4);

    final parts = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon_app.webp',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  cacheWidth: 76,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, e, s) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: LandingPalette.wine,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const SizedBox(width: 38, height: 38),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Mesa Chapaca',
                style: LandingType.heading(
                  size: 18,
                  color: LandingPalette.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'La plataforma que llena mesas y ordena salones. Hecha con carino en Tarija, Bolivia, para los restaurantes de todo el pais.',
              style: LandingType.bodyText(size: 14, height: 1.55),
            ),
          ),
        ],
      ),
      _FooterColumn(
        title: 'Producto',
        links: [
          _FooterLink('Beneficios', onBenefits),
          _FooterLink('Como funciona', onHowItWorks),
          _FooterLink('Tu perfil', onProfile),
          _FooterLink('Preguntas', onFaq),
        ],
      ),
      _FooterColumn(
        title: 'Restaurantes',
        links: [
          _FooterLink('Historias', onRestaurants),
          _FooterLink('Registrar mi restaurante', onAccess ?? onRegister),
          _FooterLink('Solicitar acceso', onAccess ?? onRegister),
        ],
      ),
      _FooterColumn(
        title: 'Contacto',
        links: [
          _FooterLink('hola@mesachapaca.bo', () => _open(Uri.parse('mailto:hola@mesachapaca.bo'))),
          _FooterLink('+591 700 00000', () => _open(Uri.parse('tel:+591700000000'))),
          _FooterLink('Tarija, Bolivia', () => _open(Uri.parse('https://maps.google.com/?q=Tarija,Bolivia'))),
        ],
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LandingPalette.paper,
        border: Border(top: BorderSide(color: LandingPalette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 56, horizontal, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: LandingLayout.maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResponsiveGrid(columns: columns, gap: 40, children: parts),
                  const SizedBox(height: 44),
                  const Divider(height: 1, color: LandingPalette.line),
                  const SizedBox(height: 26),
                  LayoutBuilder(
                    builder: (_, box) => box.maxWidth < 560
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2025 Mesa Chapaca. Todos los derechos reservados.',
                                style: LandingType.bodyText(size: 13),
                              ),
                              const SizedBox(height: 8),
                              Text('Terminos - Privacidad', style: LandingType.bodyText(size: 13)),
                            ],
                          )
                        : Row(
                            children: [
                              Text(
                                '2025 Mesa Chapaca. Todos los derechos reservados.',
                                style: LandingType.bodyText(size: 13),
                              ),
                              const Spacer(),
                              Text('Terminos - Privacidad', style: LandingType.bodyText(size: 13)),
                            ],
                          ),
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

class _FooterLink {
  const _FooterLink(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});
  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: LandingType.bodyText(
              size: 12,
              weight: FontWeight.w700,
              color: LandingPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final link in links)
            TextButton(
              onPressed: link.onTap,
              style: TextButton.styleFrom(
                foregroundColor: LandingPalette.ink,
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: LandingType.bodyText(
                  size: 14.5,
                  color: LandingPalette.ink,
                  weight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              child: Text(link.label),
            ),
        ],
      );
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.columns,
    required this.gap,
    required this.children,
  });
  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) SizedBox(height: gap),
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final end = (i + columns).clamp(0, children.length);
      final rowItems = children.sublist(i, end);
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int j = 0; j < rowItems.length; j++) ...[
            Expanded(child: rowItems[j]),
            if (j != rowItems.length - 1) SizedBox(width: gap),
          ],
          for (int j = rowItems.length; j < columns; j++) ...[
            SizedBox(width: gap),
            const Expanded(child: SizedBox()),
          ],
        ],
      ));
      if (i + columns < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}
