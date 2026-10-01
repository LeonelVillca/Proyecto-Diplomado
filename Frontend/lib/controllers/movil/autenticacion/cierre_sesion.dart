part of '../auth_controller.dart';

extension _CierreSesion on AuthController {
  /// Cierra la sesión (real o simulada) y vuelve al inicio.
  Future<void> _cerrarSesion() async {
    final previous = _token;
    _mensajeError = null;
    _generacionSesion++;
    await NotificationsService.stop(previousToken: previous);
    if (previous != null) {
      try {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/cerrar-sesiones'),
              headers: {'Authorization': 'Bearer $previous'},
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200)
          throw StateError('No se pudieron cerrar las sesiones remotas');
      } catch (_) {
        // El cierre local continúa aunque falle el cierre remoto; no mostramos
        // este fallo después de volver a Login.
      }
    }
    try {
      if (!_demoMode && !kIsWeb) {
        // En google_sign_in ^7.0.0, disconnect() revoca la cuenta a nivel OS.
        // Se llama ANTES de signOut() para evitar excepciones por no tener sesión activa.
        await GoogleSignIn.instance.disconnect();
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Si no había sesión de Google, ignoramos el error.
    }
    if (!_demoMode) {
      await _cerrarGoogle();
    }
    await _session.eliminarToken();
    _user = null;
    _demoMode = false;
    _demoName = null;
    _demoEmail = null;
    _limpiarSesionBackend();
    _status = AuthStatus.idle;
    notifyListeners();
  }
}
