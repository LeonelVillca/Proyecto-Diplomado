import 'dart:convert';
import 'dart:async';
import 'package:frontend/services/shared/secure_http.dart' show SessionHttp;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/services/shared/session_service.dart';
import 'package:frontend/core/movil/api_config.dart';

/// Estados posibles del flujo de inicio de sesión.
enum AuthStatus {
  /// Sin interacción del usuario todavía.
  idle,

  /// Proceso de autenticación en curso.
  loading,

  /// Sesión activa.
  authenticated,

  /// El usuario canceló el diálogo de Google.
  cancelled,

  /// Falló el inicio de sesión.
  error,
}

/// Maneja la sesión de Mesa Chapaca con Firebase Auth + Google Sign-In.
///
/// En web usa el popup nativo de Firebase (`signInWithPopup`), y en móvil
/// el paquete `google_sign_in` (Android / iOS). Expone el estado de carga
/// para que la UI pueda mostrar feedback y escucha los cambios de sesión.
///
/// La autenticación es **exclusivamente vía Google**: tras autenticar se
/// manda el ID Token de Firebase al backend (`POST /auth/google`), que lo
/// verifica server-side y devuelve el JWT propio, guardado en
/// [SessionService] (storage seguro). El login por correo fue eliminado por
/// ser vulnerable a suplantación.
///
/// Si [demoFallback] está activo y el inicio de sesión falla (o no hay
/// Google disponible, p. ej. en Windows), se entra automáticamente en un
/// modo de simulación con un perfil de demostración para poder recorrer la
/// app sin depender de la cuenta de Google.
class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController({
    this._firebaseAuth,
    this.demoFallback = false,   // Desactivado: errores reales deben ser visibles
    SessionService? session,
  })  : _session = session ?? SessionService() {
    _subscribeToAuthChanges();
    WidgetsBinding.instance.addObserver(this);
    SessionHttp.tokenProvider = validToken;
    SessionHttp.onUnauthorized = invalidateToken;
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isAuthenticated) unawaited(validToken().catchError((_) => null));
    });
  }

  final FirebaseAuth? _firebaseAuth;

  /// Persistencia segura del JWT del backend.
  final SessionService _session;
  Timer? _refreshTimer;
  Future<String?>? _refreshInFlight;
  StreamSubscription<User?>? _authSubscription;
  int _sessionGeneration = 0;
  bool _disposed = false;

  /// Si es `true`, los fallos de Google caen a un perfil simulado.
  final bool demoFallback;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.idle;
  User? _user;
  String? _errorMessage;
  bool _demoMode = false;
  String? _demoName;
  String? _demoEmail;

  // Sesión con el backend (vía Google). El JWT vive en `SessionService`.
  String? _token;
  String? _backendNombre;
  String? _backendApellido;
  String? _backendEmail;
  int? _backendId;
  List<String> _roles = [];
  List<String> _permisos = [];

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  List<String> get roles => _roles;
  List<String> get permisos => _permisos;
  int? get idUsuario => _backendId;

  bool hasRole(String role) => _roles.contains(role);
  bool hasPermiso(String permiso) => _permisos.contains(permiso);

  /// `true` cuando se está navegando con el perfil de demostración.
  bool get isDemo => _demoMode;

  /// Token JWT emitido por el backend para la sesión activa.
  String? get token => _token;

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(payload)));
    } catch (_) {
      return {};
    }
  }

  // Los getters de perfil usan primero el usuario del backend y luego el
  // perfil de Firebase o el simulado, así la UI no necesita saber de dónde
  // viene la sesión.
  String? get displayName {
    if (_backendNombre != null) {
      final apellido = _backendApellido?.trim() ?? '';
      final base = _backendNombre!.trim();
      return apellido.isEmpty ? base : '$base $apellido';
    }
    return _demoMode ? _demoName : _user?.displayName;
  }

  String? get email {
    if (_backendEmail != null) return _backendEmail;
    return _demoMode ? _demoEmail : _user?.email;
  }

  String? get photoUrl => _demoMode ? null : _user?.photoURL;

  /// Original de Firebase, sin el nombre de pila recortado.
  User? get firebaseUser => _user;

  /// Preparación opcional del sign-in de Google.
  ///
  /// En web no hace falta (se usa `signInWithPopup`). En móvil inicializa
  /// el singleton de `google_sign_in`, sin bloquear el arranque si falla.
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // La UI no debe romperse si la inicialización nativa falla.
    }
  }

  void _subscribeToAuthChanges() {
    try {
      _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
        // Solo actualizamos el usuario de Firebase.
        // El estado `authenticated` LO DECIDE el backend (JWT válido).
        // Si marcamos authenticated aquí, la app entra sin validar el token.
        _user = firebaseUser;
        notifyListeners();
      });
    } catch (_) {
      // Sin Firebase disponible (p. ej. en tests de widget) se mantiene idle.
    }
  }

  /// Intenta restaurar una sesión previa guardada en [SessionService].
  Future<bool> restaurarSesion() async {
    final generation = _sessionGeneration;
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

      if (generation != _sessionGeneration || _disposed) return false;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        
        final jwtData = _decodeJwt(token);
        _permisos = (jwtData['permisos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        _token = token;
        _backendNombre = (data['nombre'] as String?)?.trim();
        _backendApellido = data['apellido'] as String?;
        _backendEmail = data['correo'] as String?;
        _backendId = data['id'] as int? ?? data['idUsuario'] as int? ?? data['id_usuario'] as int?;
        _roles = (data['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
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
      if (response.statusCode != 401 && response.statusCode != 403) return false;
      await _session.eliminarToken();
      _limpiarSesionBackend();
      _status = AuthStatus.idle;
      notifyListeners();
      return false;
    } catch (_) {
      // Sin conexión no podemos validar; se va al login pero se conserva
      // el token para intentarlo de nuevo en el próximo arranque.
      _status = AuthStatus.idle;
      notifyListeners();
      return false;
    }
  }

  /// Método especial para el flujo administrativo web (login local).
  Future<bool> restaurarSesionLocalDesdeAdmin(String newToken) async {
    await _session.guardarToken(newToken);
    return restaurarSesion();
  }

  /// Inicia sesión con la cuenta de Google del usuario.
  Future<bool> signInWithGoogle() async {
    if (isLoading) return false;

    _status = AuthStatus.loading;
    _errorMessage = null;
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
      if (firebaseUser == null || firebaseUser.email == null) throw StateError('Falta la identidad de Google');
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
    } catch (_) {
      // Sin Google disponible o usuario canceló: caemos a la simulación.
      if (demoFallback) {
        enterSimulation();
        return true;
      }
      _status = AuthStatus.error;
      _errorMessage =
          'No pudimos conectar con Google. Revisa tu conexión e inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  /// Envía el ID Token de Firebase al backend.
  Future<bool> _registrarGoogleEnBackend(User firebaseUser) async {
    final generation = _sessionGeneration;
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _errorMessage =
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

      if (generation != _sessionGeneration || _disposed) return false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final usuario =
            (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};
        if (data['token'] is! String || (data['token'] as String).isEmpty || usuario['id'] == null) return false;
        _token = data['token'] as String?;
        _backendNombre = (usuario['nombre'] as String?)?.trim();
        _backendApellido = usuario['apellido'] as String?;
        _backendEmail = usuario['correo'] as String?;
        _backendId = usuario['id'] as int? ?? usuario['idUsuario'] as int? ?? usuario['id_usuario'] as int?;
        if (_token != null) {
          final jwtData = _decodeJwt(_token!);
          _permisos = (jwtData['permisos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          await _session.guardarToken(_token!);
        }
        return true;
      }

      _errorMessage =
          'Google aceptó la sesión, pero no pudimos guardarla. '
          'Revisa que el backend esté corriendo e inténtalo de nuevo.';
      return false;
    } catch (_) {
      _errorMessage = _errorDeConexion;
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
  void enterSimulation() {
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
    final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
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

  void _limpiarSesionBackend() {
    _token = null;
    _backendNombre = null;
    _backendApellido = null;
    _backendEmail = null;
    _backendId = null;
    _roles = [];
    _permisos = [];
  }

  Future<String?> validToken() async {
    if (_token == null || _disposed) return null;
    final exp = _decodeJwt(_token!)['exp'];
    if (exp is! num || exp * 1000 <= DateTime.now().millisecondsSinceEpoch) {
      if (await _reautenticarBackendDesdeFirebase()) return _token;
      await invalidateToken(_token!);
      return null;
    }
    if (exp * 1000 - DateTime.now().millisecondsSinceEpoch > 5 * 60 * 1000) return _token;
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final future = _renewToken();
    _refreshInFlight = future;
    try { return await future; } finally { if (identical(_refreshInFlight, future)) _refreshInFlight = null; }
  }

  Future<String?> _renewToken() async {
    final previous = _token;
    final generation = _sessionGeneration;
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/renovar'),
      headers: {'Authorization': 'Bearer $previous'}).timeout(const Duration(seconds: 10));
    if (_disposed || generation != _sessionGeneration || previous != _token) return null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      if (await _reautenticarBackendDesdeFirebase()) return _token;
      await invalidateToken(previous!);
      return null;
    }
    if (response.statusCode != 200) throw StateError('No se pudo renovar la sesión');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final renewed = data['token'];
    if (renewed is! String || renewed.isEmpty) throw StateError('Respuesta de sesión inválida');
    await _session.guardarToken(renewed);
    if (_disposed || generation != _sessionGeneration) { await _session.eliminarToken(); return null; }
    _token = renewed;
    _permisos = (_decodeJwt(renewed)['permisos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    notifyListeners();
    return renewed;
  }

  /// Recupera la sesión del backend usando la sesión persistente de Firebase.
  /// Esto evita enviar al usuario al login cuando el móvil suspendió la app y
  /// el JWT propio ya expiró.
  Future<bool> _reautenticarBackendDesdeFirebase() async {
    final generation = _sessionGeneration;
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || _disposed) return false;

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

      if (_disposed || generation != _sessionGeneration) return false;
      if (response.statusCode != 200 && response.statusCode != 201) return false;

      final data = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final usuario =
          (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};
      final renewed = data['token'];
      if (renewed is! String || renewed.isEmpty || usuario['id'] == null) {
        return false;
      }

      _token = renewed;
      _backendNombre = (usuario['nombre'] as String?)?.trim();
      _backendApellido = usuario['apellido'] as String?;
      _backendEmail = usuario['correo'] as String?;
      _backendId = usuario['id'] as int? ??
          usuario['idUsuario'] as int? ??
          usuario['id_usuario'] as int?;
      final jwtData = _decodeJwt(renewed);
      _permisos = (jwtData['permisos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      await _session.guardarToken(renewed);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> invalidateToken(String rejected) async {
    if (rejected != _token) return;
    _sessionGeneration++;
    _limpiarSesionBackend();
    _status = AuthStatus.idle;
    await _session.eliminarToken();
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAuthenticated) unawaited(validToken().catchError((_) => null));
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionGeneration++;
    _refreshTimer?.cancel();
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SessionHttp.tokenProvider = null;
    SessionHttp.onUnauthorized = null;
    super.dispose();
  }

  /// Cierra la sesión (real o simulada) y vuelve al inicio.
  Future<void> signOut() async {
    final previous = _token;
    _errorMessage = null;
    _sessionGeneration++;
    if (previous != null) {
      try {
        final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/cerrar-sesiones'),
          headers: {'Authorization': 'Bearer $previous'}).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) throw StateError('No se pudieron cerrar las sesiones remotas');
      } catch (_) {
        _errorMessage = 'Se cerró la sesión en este dispositivo, pero no se pudo confirmar el cierre en los demás.';
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

/// Permite exponer [AuthController] a todo el árbol sin dependencias externas.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController authController,
    required super.child,
  }) : super(notifier: authController);

  static AuthController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AuthScope>()
        : context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'Se requiere un AuthScope por encima del widget.');
    return scope!.notifier!;
  }
}
