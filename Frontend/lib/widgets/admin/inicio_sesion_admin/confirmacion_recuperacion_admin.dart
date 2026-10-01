part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _ConfirmacionRecuperacionAdmin on _AdminLoginScreenState {
  Widget _buildExito() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: authInk.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: authSage.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: authSage,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Contrasena actualizada!',
            style: GoogleFonts.piazzolla(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: authInk,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ya puedes iniciar sesion con tu nueva contrasena.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: authInkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: 'Volver a iniciar sesion',
            loading: false,
            onPressed: () {
              _correoCtrl.text = _recoveryCorreoCtrl.text;
              _passwordCtrl.clear();
              _nuevaPasswordCtrl.clear();
              _confirmPasswordCtrl.clear();
              for (var c in _pinCtrls) {
                c.clear();
              }
              setState(() => _screenState = AuthScreenState.login);
            },
          ),
        ],
      ),
    );
  }
}

class ConfirmacionRecuperacionAdmin extends StatelessWidget {
  const ConfirmacionRecuperacionAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildExito();
}
