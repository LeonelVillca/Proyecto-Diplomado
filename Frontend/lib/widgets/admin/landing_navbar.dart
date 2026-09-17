import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    this.onBenefits,
    this.onHowItWorks,
    this.onRestaurants,
    this.onContact,
    this.onLogin,
    this.onRegister,
    this.showLinks = true,
    super.key,
  });

  final VoidCallback? onBenefits;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onRestaurants;
  final VoidCallback? onContact;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final bool showLinks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < LandingLayout.desktop;
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 80,
              padding: EdgeInsets.symmetric(
                horizontal: LandingLayout.horizontalPadding(width),
              ),
              decoration: const BoxDecoration(
                color: Color(0xEDF7F1E7),
                border: Border(bottom: BorderSide(color: LandingPalette.line)),
              ),
              child: Semantics(
                container: true,
                label: 'Navegación principal',
                child: Row(
                  children: [
                    const _Brand(),
                    const Spacer(),
                    if (showLinks && !compact) ...[
                      _NavAction(label: 'Beneficios', onPressed: onBenefits),
                      _NavAction(
                        label: 'Cómo funciona',
                        onPressed: onHowItWorks,
                      ),
                      _NavAction(
                        label: 'Restaurantes',
                        onPressed: onRestaurants,
                      ),
                      _NavAction(label: 'Contacto', onPressed: onContact),
                      const SizedBox(width: 12),
                      _LoginButton(onPressed: onLogin),
                      const SizedBox(width: 10),
                      _RegisterButton(onPressed: onRegister),
                    ] else if (showLinks) ...[
                      if (width >= 900)
                        _LoginButton(onPressed: onLogin),
                      if (width >= 900)
                        const SizedBox(width: 8),
                      _MenuButton(
                        onBenefits: onBenefits,
                        onHowItWorks: onHowItWorks,
                        onRestaurants: onRestaurants,
                        onContact: onContact,
                        onLogin: onLogin,
                        onRegister: onRegister,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Mesa Chapaca',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon_app.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                cacheWidth: 84,
                filterQuality: FilterQuality.medium,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mesa Chapaca',
              style: LandingType.heading(size: 19, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: LandingPalette.ink,
        minimumSize: const Size(48, 48),
        textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: LandingPalette.wine,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: LandingPalette.wine),
        textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w700),
      ),
      child: const Text('Iniciar sesión'),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LandingPalette.wine,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        textStyle: LandingType.bodyText(
          size: 15,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      child: const Text('Registrar restaurante'),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.onBenefits,
    required this.onHowItWorks,
    required this.onRestaurants,
    required this.onContact,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback? onBenefits;
  final VoidCallback? onHowItWorks;
  final VoidCallback? onRestaurants;
  final VoidCallback? onContact;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  Future<void> _showMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LandingPalette.card,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Explorar Mesa Chapaca',
                style: LandingType.heading(size: 26),
              ),
              const SizedBox(height: 12),
              _SheetAction(value: 'benefits', label: 'Beneficios'),
              _SheetAction(value: 'how', label: 'Cómo funciona'),
              _SheetAction(value: 'restaurants', label: 'Restaurantes'),
              _SheetAction(value: 'contact', label: 'Contacto'),
              const Divider(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'login'),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'register'),
                style: FilledButton.styleFrom(
                  backgroundColor: LandingPalette.wine,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Registrar restaurante'),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'benefits':
        onBenefits?.call();
        return;
      case 'how':
        onHowItWorks?.call();
        return;
      case 'restaurants':
        onRestaurants?.call();
        return;
      case 'contact':
        onContact?.call();
        return;
      case 'login':
        onLogin?.call();
        return;
      case 'register':
        onRegister?.call();
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => _showMenu(context),
      tooltip: 'Abrir menú',
      icon: const Icon(Icons.menu_rounded),
      color: LandingPalette.wine,
      iconSize: 24,
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 48,
      title: Text(
        label,
        style: LandingType.bodyText(color: LandingPalette.ink),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
