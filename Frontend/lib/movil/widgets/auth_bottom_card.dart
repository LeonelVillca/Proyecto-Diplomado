import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'google_sign_in_button.dart';

/// Tarjeta flotante con las acciones de acceso.
///
/// Fondo blanco, esquinas redondeadas y una sombra suave en capas para
/// flotar sobre el fondo crema. Contiene el título, el botón de Google, la
/// alternativa de entrar con el correo (que el backend guarda y con la que
/// la app saluda por nombre) y el texto legal.
class AuthBottomCard extends StatefulWidget {
  const AuthBottomCard({super.key, required this.auth});

  /// Proveedor de autenticación que alimenta las acciones de acceso.
  final AuthProvider auth;

  @override
  State<AuthBottomCard> createState() => _AuthBottomCardState();
}

class _AuthBottomCardState extends State<AuthBottomCard> {
  final TextEditingController _emailController = TextEditingController();

  AuthProvider get auth => widget.auth;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarCorreo() async {
    final correo = _emailController.text.trim();
    if (correo.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    await auth.signInWithEmail(correo);
  }

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
              if (auth.errorMessage != null) ...[
                _ErrorBanner(message: auth.errorMessage!),
                const SizedBox(height: 14),
              ],
              ListenableBuilder(
                listenable: auth,
                builder: (context, _) => GoogleSignInButton(
                  isLoading: auth.isLoading,
                  onPressed: () => auth.signInWithGoogle(),
                ),
              ),
              _OrDivider(),
              TextField(
                controller: _emailController,
                enabled: !auth.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onSubmitted: (_) => _enviarCorreo(),
                decoration: InputDecoration(
                  hintText: 'tu@correo.com',
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: AppColors.onCardMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.6,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: auth,
                builder: (context, _) => FilledButton(
                  onPressed: auth.isLoading ? null : _enviarCorreo,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continuar con mi correo',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
              const SizedBox(height: 4),
              TextButton(
                onPressed: auth.enterSimulation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.gold,
                ),
                child: Text(
                  'Entrar en modo demo 👀',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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

/// Separador "o" entre el acceso con Google y el correo.
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE9E2D5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'o',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onCardMuted,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE9E2D5))),
        ],
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