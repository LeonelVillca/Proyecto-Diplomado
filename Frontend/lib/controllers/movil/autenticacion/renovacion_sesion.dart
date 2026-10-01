part of '../auth_controller.dart';

extension _RenovacionSesion on AuthController {
  void _limpiarSesionBackend() {
    _token = null;
    _backendNombre = null;
    _backendApellido = null;
    _backendEmail = null;
    _backendId = null;
    _roles = [];
    _permisos = [];
  }

  Future<String?> _obtenerTokenValido() async {
    if (_token == null || _disposeRealizado) return null;
    final exp = _decodificarJwt(_token!)['exp'];
    if (exp is! num || exp * 1000 <= DateTime.now().millisecondsSinceEpoch) {
      if (await _reautenticarBackendDesdeFirebase()) return _token;
      await _invalidarToken(_token!);
      return null;
    }
    if (exp * 1000 - DateTime.now().millisecondsSinceEpoch > 5 * 60 * 1000)
      return _token;
    final pending = _renovacionEnCurso;
    if (pending != null) return pending;
    final future = _renovarToken();
    _renovacionEnCurso = future;
    try {
      return await future;
    } finally {
      if (identical(_renovacionEnCurso, future)) _renovacionEnCurso = null;
    }
  }

  Future<String?> _renovarToken() async {
    final previous = _token;
    final generation = _generacionSesion;
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/renovar'),
          headers: {'Authorization': 'Bearer $previous'},
        )
        .timeout(const Duration(seconds: 10));
    if (_disposeRealizado ||
        generation != _generacionSesion ||
        previous != _token)
      return null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      if (await _reautenticarBackendDesdeFirebase()) return _token;
      await _invalidarToken(previous!);
      return null;
    }
    if (response.statusCode != 200)
      throw StateError('No se pudo renovar la sesión');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final renewed = data['token'];
    if (renewed is! String || renewed.isEmpty)
      throw StateError('Respuesta de sesión inválida');
    await _session.guardarToken(renewed);
    if (_disposeRealizado || generation != _generacionSesion) {
      await _session.eliminarToken();
      return null;
    }
    _token = renewed;
    _permisos =
        (_decodificarJwt(renewed)['permisos'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    notifyListeners();
    return renewed;
  }

  /// Recupera la sesión del backend usando la sesión persistente de Firebase.
  /// Esto evita enviar al usuario al login cuando el móvil suspendió la app y
  /// el JWT propio ya expiró.
  Future<bool> _reautenticarBackendDesdeFirebase() async {
    final generation = _generacionSesion;
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || _disposeRealizado) return false;

    try {
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) return false;

      final response = await http
          .post(
            Uri.parse(ApiConfig.authGoogle),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (_disposeRealizado || generation != _generacionSesion) return false;
      if (response.statusCode != 200 && response.statusCode != 201)
        return false;

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final usuario = (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};
      final renewed = data['token'];
      if (renewed is! String || renewed.isEmpty || usuario['id'] == null) {
        return false;
      }

      _token = renewed;
      _backendNombre = (usuario['nombre'] as String?)?.trim();
      _backendApellido = usuario['apellido'] as String?;
      _backendEmail = usuario['correo'] as String?;
      _backendId =
          usuario['id'] as int? ??
          usuario['idUsuario'] as int? ??
          usuario['id_usuario'] as int?;
      final jwtData = _decodificarJwt(renewed);
      _permisos =
          (jwtData['permisos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      await _session.guardarToken(renewed);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _invalidarToken(String rejected) async {
    if (rejected != _token) return;
    _generacionSesion++;
    _limpiarSesionBackend();
    _status = AuthStatus.idle;
    await NotificationsService.stop();
    await _session.eliminarToken();
    if (!_disposeRealizado) notifyListeners();
  }
}
