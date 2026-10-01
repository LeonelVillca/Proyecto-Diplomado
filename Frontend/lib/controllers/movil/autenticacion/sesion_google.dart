part of '../auth_controller.dart';

extension _FlujoGoogle on AuthController {
  /// Intenta restaurar una sesión previa guardada en [SessionService].
  Future<bool> _restaurarSesion() async {
    final generation = _generacionSesion;
    final token = await _session.obtenerToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.authPerfil),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (generation != _generacionSesion || _disposeRealizado) return false;
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        final jwtData = _decodificarJwt(token);
        _permisos =
            (jwtData['permisos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        _token = token;
        _backendNombre = (data['nombre'] as String?)?.trim();
        _backendApellido = data['apellido'] as String?;
        _backendEmail = data['correo'] as String?;
        _backendId =
            data['id'] as int? ??
            data['idUsuario'] as int? ??
            data['id_usuario'] as int?;
        _roles =
            (data['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      // El JWT del backend puede haber expirado mientras el sistema suspendía
      // la app. Firebase conserva la sesión de Google y permite reconstruir
      // el JWT sin mostrar nuevamente el login.
      if (response.statusCode == 401 || response.statusCode == 403) {
        if (await _reautenticarBackendDesdeFirebase()) {
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      }

      // No borrar credenciales por una caída temporal del servidor.
      if (response.statusCode != 401 && response.statusCode != 403)
        return false;
      await _session.eliminarToken();
      _limpiarSesionBackend();
      _status = AuthStatus.idle;
      notifyListeners();
      return false;
    } catch (_) {{
      // Sin conexión no podemos validar; se va al login pero se conserva
      // el token para intentarlo de nuevo en el próximo arranque.
      _status = AuthStatus.idle;
      notifyListeners();
      return false;
    }
  }

  /// Inicia sesión con la cuenta de Google del usuario.
  Future<bool> _iniciarSesionConGoogle() async {
    if (isLoading) return false;

    _status = AuthStatus.loading;
    _mensajeError = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final credential = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(credential);
        _user = userCredential.user;
      } else {
        await _signInWithGoogleMobile();
      }
      _user = _auth.currentUser;

      final firebaseUser = _user;
      if (firebaseUser == null || firebaseUser.email == null)
        throw StateError('Falta la identidad de Google');
      if (firebaseUser.email != null) {
        final registrado = await _registrarGoogleEnBackend(firebaseUser);
        if (!registrado) {
          await _cerrarGoogle();
          _user = null;
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        }
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error) {
      // Registrar solo códigos: nunca tokens ni datos de la cuenta.
      if (error is GoogleSignInException) {
        debugPrint('[AuthGoogle] Google Sign-In: ${error.code.name}');
      } else if (error is FirebaseAuthException) {
        debugPrint('[AuthGoogle] Firebase Auth: ${error.code}');
      } else {
        debugPrint('[AuthGoogle] Fallo de autenticación: ${error.runtimeType}');
      }
      // Sin Google disponible o usuario canceló: caemos a la simulación.
      if (demoFallback) {
        _entrarModoSimulacion();
        return true;
      }
      _status = AuthStatus.error;
      _mensajeError =
          'No pudimos conectar con Google. Revisa tu conexión e inténtalo de nuevo.';
      if (error is GoogleSignInException &&
          (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
              error.code == GoogleSignInExceptionCode.providerConfigurationError)) {
        _mensajeError = 'El inicio de sesión con Google no está configurado correctamente. '
            'Revisa la configuración de Google y Firebase de la app.';
      } else if (error is FirebaseAuthException &&
          error.code == 'operation-not-allowed') {
        _mensajeError = 'El inicio de sesión con Google no está habilitado en Firebase.';
      }
      notifyListeners();
      return false;
    }
  }

  /// Envía el ID Token de Firebase al backend.
  Future<bool> _registrarGoogleEnBackend(User firebaseUser) async {
    final generation = _generacionSesion;
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _mensajeError =
            'No pudimos obtener el token de tu sesión de Google. '
            'Inténtalo de nuevo.';
        return false;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.authGoogle),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (generation != _generacionSesion || _disposeRealizado) return false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final usuario =
            (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};
        if (data['token'] is! String ||
            (data['token'] as String).isEmpty ||
            usuario['id'] == null)
          return false;
        _token = data['token'] as String?;
        _backendNombre = (usuario['nombre'] as String?)?.trim();
        _backendApellido = usuario['apellido'] as String?;
        _backendEmail = usuario['correo'] as String?;
        _backendId =
            usuario['id'] as int? ??
            usuario['idUsuario'] as int? ??
            usuario['id_usuario'] as int?;
        if (_token != null) {
          final jwtData = _decodificarJwt(_token!);
          _permisos =
              (jwtData['permisos'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          await _session.guardarToken(_token!);
        }
        return true;
      }

      _mensajeError =
          'Google aceptó la sesión, pero no pudimos guardarla. '
          'Revisa que el backend esté corriendo e inténtalo de nuevo.';
      return false;
    } catch (_) {
      _mensajeError = _errorDeConexion;
      return false;
    }
  }

  Future<void> _cerrarGoogle() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (_) {
      // Si la sesión de Google ya no existía, se ignora.
    }
  }

  /// Entra manualmente al modo de demostración (útil para maquetas).
  void _entrarModoSimulacion() {
    if (!kDebugMode || !demoFallback) return;
    _demoMode = true;
    _demoName = 'Kevin Chapaco';
    _demoEmail = 'demo@mesachapaca.dev';
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Mensaje descriptivo cuando el backend no responde.
  String get _errorDeConexion =>
      'No pudimos conectar con el servidor de Mesa Chapaca '
      '(${ApiConfig.baseUrl}). Verifica que el backend esté corriendo y que '
      'este sea el acceso correcto desde tu dispositivo.';
  Future<void> _signInWithGoogleMobile() async {
    final GoogleSignInAccount? account = await GoogleSignIn.instance
        .authenticate();
    if (account == null) {
      throw Exception('Cancelado por el usuario.');
    }
    final GoogleSignInAuthentication authTokens = await account.authentication;
    final idToken = authTokens.idToken;
    if (idToken == null) {
      throw Exception('No se pudo obtener el ID token de Google.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }
}
