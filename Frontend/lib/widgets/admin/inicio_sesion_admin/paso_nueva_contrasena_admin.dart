part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _PasoNuevaContrasenaAdmin on _AdminLoginScreenState {
  bool get _hasMinLength =>
      PasswordPolicy.hasMinimumLength(_nuevaPasswordCtrl.text);

  bool get _hasRegex =>
      PasswordPolicy.hasUppercase(_nuevaPasswordCtrl.text) &&
      PasswordPolicy.hasLowercase(_nuevaPasswordCtrl.text) &&
      PasswordPolicy.hasNumberOrSymbol(_nuevaPasswordCtrl.text);

  bool get _hasMatch =>
      _nuevaPasswordCtrl.text == _confirmPasswordCtrl.text &&
      _nuevaPasswordCtrl.text.isNotEmpty;

  Widget _buildChecklistItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.check_circle_outline,
            color: isValid ? authSage : const Color(0xFFB5A89D),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                color: isValid ? authSage : authInkSoft,
                fontWeight: isValid ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          this._buildRecoveryHeader(
            3,
            onBack: () =>
                setState(() => _screenState = AuthScreenState.paso2Pin),
            title: 'Crea una nueva contrasena',
            subtitle: 'Elige una contrasena segura que no hayas usado antes.',
          ),
          AuthLoginField(
            controller: _nuevaPasswordCtrl,
            label: 'Nueva contrasena',
            hintText: 'Escribe tu nueva contrasena',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
            validator: PasswordPolicy.validate,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRecoveryText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: authInkFaint,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureRecoveryText = !_obscureRecoveryText),
            ),
          ),
          const SizedBox(height: 24),
          AuthLoginField(
            controller: _confirmPasswordCtrl,
            label: 'Confirmar contrasena',
            hintText: 'Vuelve a escribir la contrasena',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
            validator: (value) => PasswordPolicy.validateConfirmation(
              _nuevaPasswordCtrl.text,
              value,
            ),
          ),
          const SizedBox(height: 24),
          this._buildChecklistItem('Al menos 8 caracteres', _hasMinLength),
          this._buildChecklistItem(
            'Incluye mayuscula, minuscula y un numero o simbolo',
            _hasRegex,
          ),
          this._buildChecklistItem('Las contrasenas coinciden', _hasMatch),
          this._buildInlineMessage(),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: 'Guardar contrasena',
            loading: _isLoading,
            onPressed: _restablecerPassword,
          ),
        ],
      ),
    );
  }
}

class PasoNuevaContrasenaAdmin extends StatelessWidget {
  const PasoNuevaContrasenaAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso3();
}
