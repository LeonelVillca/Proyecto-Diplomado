import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_bottom_card.dart';

/// Pantalla de inicio de sesión de Mesa Chapaca.
///
/// Diseño claro y editorial: fondo crema cálido con un resplandor suave de
/// atardecer arriba, la marca centrada con espacio y una tarjeta flotante
/// blancaal pie con la acción principal (Continuar con Google).
///
/// Entrada en cascada: primero aparece el branding y luego sube la tarjeta.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Branding: aparecer + ligero descenso suave.
  late final Animation<double> _brandFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );
  late final Animation<Offset> _brandSlide = Tween<Offset>(
    begin: const Offset(0, -0.06),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ),
  );

  // Tarjeta: subir desde abajo + fade (arranca después del branding).
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardSlide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo cálido con resplandor de atardecer.
            const _BackgroundScene(),
            SafeArea(
              child: Column(
                children: [
                  // Marca centrada en la mitad superior.
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _brandFade,
                        child: SlideTransition(
                          position: _brandSlide,
                          child: const _BrandPanel(),
                        ),
                      ),
                    ),
                  ),
                  // Tarjeta flotante con la acción principal.
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: AuthBottomCard(auth: auth),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo crema con un resplandor cálido superior y un tinte de vino sutil
/// que asoma detrás de la tarjeta.
class _BackgroundScene extends StatelessWidget {
  const _BackgroundScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAF3E7),
            AppColors.background,
            Color(0xFFF3E9D8),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Resplandor dorado del atardecer arriba.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.95),
                radius: 1.15,
                colors: [Color(0x59E0A55C), Color(0x00E0A55C)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Tinte de vino que asoma en la base.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00151516), Color(0x2E5C1A2E)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca: icono pequeño, wordmark y una breve línea de valor.
/// Composición aireada, sin adornos sobre las letras.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Firma pequeña de la casa.
          Image.asset(
            'assets/tarija_app_icon.png',
            height: 84,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          Text(
            'Mesa Chapaca',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 33,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: AppColors.wine,
            ),
          ),
          const SizedBox(height: 12),
          // Acento dorado bajo el nombre.
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'Descubre y reserva en los mejores restaurantes de Tarija',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}