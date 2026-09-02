import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'google_sign_in_button.dart';

/// Tarjeta flotante con la acción de acceso.
///
/// Fondo blanco, esquinas redondeadas y una sombra suave en capas para
/// flotar sobre el fondo crema. Contiene el título, el botón de Google y el
/// texto legal. La autenticación es exclusivamente vía Google.
class AuthBottomCard extends StatefulWidget {
  const AuthBottomCard({super.key, required this.auth});

  /// Proveedor de autenticación que alimenta la acción de acceso.
  final AuthController auth;

  @override
  State<AuthBottomCard> createState() => _AuthBottomCardState();
}

class _AuthBottomCardState extends State<AuthBottomCard> {
  AuthController get auth => widget.auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Comenzar',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.onCard,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa para hacer tu reserva',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onCardMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: auth,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (auth.errorMessage != null) ...[
                      _ErrorBanner(message: auth.errorMessage!),
                      const SizedBox(height: 14),
                    ],
                    GoogleSignInButton(
                      isLoading: auth.isLoading,
                      onPressed: () async {
                        final success = await auth.signInWithGoogle();
                        if (success && context.mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Al continuar aceptas nuestros Términos de Uso '
                'y Política de Privacidad.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onCardMuted.withAlpha(200),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de error de autenticación, integrado a la tarjeta.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.wine.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wine.withAlpha(48)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.wine, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.wine,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
