part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _PasoCorreoRecuperacionAdmin on _AdminLoginScreenState {
  Widget _buildPaso1() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          this._buildRecoveryHeader(
            1,
            onBack: () => setState(() => _screenState = AuthScreenState.login),
            title: 'Recupera tu contrasena',
            subtitle:
                'Ingresa el correo asociado a tu cuenta y te enviaremos un codigo de verificacion.',
          ),
          AuthLoginField(
            controller: _recoveryCorreoCtrl,
            label: 'Correo electronico',
            hintText: 'tunombre@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Correo invalido' : null,
          ),
          this._buildInlineMessage(),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: 'Enviar codigo',
            loading: _isLoading,
            onPressed: _solicitarRecuperacion,
          ),
        ],
      ),
    );
  }
}

class PasoCorreoRecuperacionAdmin extends StatelessWidget {
  const PasoCorreoRecuperacionAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso1();
}
