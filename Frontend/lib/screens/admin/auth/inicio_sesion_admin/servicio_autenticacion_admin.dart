part of '../admin_login_screen.dart';

extension _ServicioAutenticacionAdmin on _AdminLoginScreenState {
  void _mostrarMensaje(String msg, {bool isError = true}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = msg;
      _inlineMessageIsError = isError;
    });
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _correoCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        if (token != null && mounted) {
          final auth = AuthScope.of(context);
          final success = await auth.restaurarSesionLocalDesdeAdmin(token);
          if (success && mounted) {
            if (auth.hasRole('admin_sistema')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSistemaDashboard(),
                ),
              );
            } else if (auth.hasRole('admin_restaurante')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRestauranteDashboard(),
                ),
              );
            } else {
              auth.signOut();
              if (!mounted) return;
              this._mostrarMensaje(
                'Tu cuenta no tiene permisos para acceder al Panel Administrativo. Contacta a soporte si crees que es un error.',
              );
            }
          }
        }
      } else {
        this._mostrarMensaje('Credenciales invalidas o cuenta suspendida.');
      }
    } catch (_) {
      this._mostrarMensaje('Error de red. Verifica tu conexion.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _solicitarRecuperacion() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authSolicitarRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': _recoveryCorreoCtrl.text.trim()}),
        timeout: const Duration(seconds: 60),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        this._mostrarMensaje(
          authResponseMessage(
            res.body,
            'Solicitud aceptada. Si el correo está registrado, recibirás un PIN.',
          ),
          isError: false,
        );
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.paso2Pin);
      } else {
        this._mostrarMensaje(
          res.statusCode >= 500
              ? 'El servidor no pudo confirmar el envío. Si ya recibiste el correo, ingresa ese PIN; si no, espera un minuto antes de pedir otro.'
              : authHttpErrorMessage(
                  res.statusCode,
                  res.body,
                  'No se pudo solicitar el código. Revisa el correo e inténtalo nuevamente.',
                ),
        );
      }
    } on TimeoutException {
      this._mostrarMensaje(
        'La solicitud tardó demasiado y no pudimos confirmar el resultado. Si ya recibiste el correo, ingresa el PIN; si no, espera un minuto antes de pedir otro.',
      );
    } on http.ClientException {
      this._mostrarMensaje(
        'Se perdió la conexión antes de confirmar la solicitud. Si llegó el correo, usa ese PIN; si no, espera un minuto y vuelve a intentarlo.',
      );
    } catch (_) {
      this._mostrarMensaje(
        'No pudimos confirmar la solicitud. Si llegó el correo, usa ese PIN; si no, espera un minuto antes de pedir otro.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarPin() async {
    final pin = _pinCtrls.map((c) => c.text).join();
    if (pin.length < 6) {
      this._mostrarMensaje('Ingresa el codigo completo de 6 digitos.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authVerificarPinRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
        }),
        timeout: const Duration(seconds: 30),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.paso3NuevaContrasena);
      } else {
        this._mostrarMensaje(
          authHttpErrorMessage(
            res.statusCode,
            res.body,
            'El PIN es inválido o venció. Solicita un código nuevo e inténtalo otra vez.',
          ),
        );
      }
    } on TimeoutException {
      this._mostrarMensaje(
        'La verificación tardó demasiado. Comprueba tu conexión e inténtalo otra vez.',
      );
    } on http.ClientException {
      this._mostrarMensaje(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo otra vez.',
      );
    } catch (_) {
      this._mostrarMensaje(
        'No se pudo verificar el PIN. Revisa tu conexión e inténtalo otra vez.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restablecerPassword() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    final passwordError = PasswordPolicy.validate(_nuevaPasswordCtrl.text);
    final confirmationError = PasswordPolicy.validateConfirmation(
      _nuevaPasswordCtrl.text,
      _confirmPasswordCtrl.text,
    );
    if (passwordError != null || confirmationError != null) {
      this._mostrarMensaje(passwordError ?? confirmationError!);
      return;
    }
    final pin = _pinCtrls.map((c) => c.text).join();
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authRestablecerPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
          'nuevaContrasena': _nuevaPasswordCtrl.text,
        }),
        timeout: const Duration(seconds: 45),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.exito);
      } else {
        this._mostrarMensaje(
          res.statusCode >= 500
              ? 'El servidor no pudo confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.'
              : authHttpErrorMessage(
                  res.statusCode,
                  res.body,
                  'No se pudo actualizar la contraseña. Revisa el PIN y vuelve a intentarlo.',
                ),
        );
      }
    } on TimeoutException {
      this._mostrarMensaje(
        'No pudimos confirmar si se guardó la contraseña. Prueba iniciar sesión con la nueva; si no funciona, vuelve a esta pantalla e inténtalo otra vez.',
      );
    } on http.ClientException {
      this._mostrarMensaje(
        'Se perdió la conexión y no pudimos confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.',
      );
    } catch (_) {
      this._mostrarMensaje(
        'No se pudo confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
