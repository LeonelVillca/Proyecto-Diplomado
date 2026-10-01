part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _FormularioAccesoAdmin on _AdminLoginScreenState {
  Widget _buildLoginState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bienvenido de vuelta',
          style: GoogleFonts.piazzolla(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: authInk,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ingresa con tu cuenta para ver el salon de hoy.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: authInkSoft,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _loginFormKey,
          child: Column(
            children: [
              AuthLoginField(
                controller: _correoCtrl,
                label: 'Correo electronico',
                hintText: 'correo@turestaurante.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Correo invalido' : null,
              ),
              const SizedBox(height: 24),
              AuthLoginField(
                controller: _passwordCtrl,
                label: 'Contrasena',
                hintText: 'Tu contrasena',
                icon: Icons.lock_outline,
                obscureText: _obscureText,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                onFieldSubmitted: (_) => this._login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authInkFaint,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ],
          ),
        ),
        this._buildInlineMessage(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: authWine,
                    side: const BorderSide(
                      color: Color(0xFFDCD6CC),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recordarme',
                  style: GoogleFonts.manrope(
                    color: authInkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                _recoveryCorreoCtrl.text = _correoCtrl.text;
                setState(() => _screenState = AuthScreenState.paso1Correo);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
              ),
              child: Text(
                'Olvidaste tu contrasena?',
                style: GoogleFonts.manrope(
                  color: authWine,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        AuthSubmitButton(
          label: 'Ingresar a mi panel',
          loading: _isLoading,
          onPressed: _login,
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFF0EBE1), height: 1),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Todavia no tienes cuenta? ',
              style: GoogleFonts.manrope(
                color: authInkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SolicitudRegistroScreen(),
                ),
              ),
              child: Text(
                'Registra tu restaurante',
                style: GoogleFonts.manrope(
                  color: authWine,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FormularioAccesoAdmin extends StatelessWidget {
  const FormularioAccesoAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildLoginState();
}
