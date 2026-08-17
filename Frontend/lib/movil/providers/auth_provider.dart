import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/services/session_service.dart';
import '../core/api_config.dart';

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
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    this._firebaseAuth,
    this.demoFallback = true,
    SessionService? session,
  })  : _session = session ?? SessionService() {
    _subscribeToAuthChanges();
  }

  final FirebaseAuth? _firebaseAuth;

  /// Persistencia segura del JWT del backend.
  final SessionService _session;

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

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  List<String> get roles => _roles;
  int? get idUsuario => _backendId;

  bool hasRole(String role) => _roles.contains(role);

  /// `true` cuando se está navegando con el perfil de demostración.
  bool get isDemo => _demoMode;

  /// Token JWT emitido por el backend para la sesión activa.
  String? get token => _token;

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
      _auth.authStateChanges().listen((firebaseUser) {
        _user = firebaseUser;
        if (firebaseUser != null) {
          _status = AuthStatus.authenticated;
        }
        notifyListeners();
      });
    } catch (_) {
      // Sin Firebase disponible (p. ej. en tests de widget) se mantiene idle.
    }
  }

  /// Intenta restaurar una sesión previa guardada en [SessionService].
  ///
  /// Lee el JWT y lo valida contra `GET /auth/perfil`. Si el backend
  /// responde 401 (token vencido/inválido) se limpia el storage y se
  /// retorna `false` (el usuario vuelve al login). Si no hay token o hay
  /// problemas de conexión se retorna `false` sin tocar el storage.
  ///
  /// Retorna `true` si la sesión quedó activa.
  Future<bool> restaurarSesion() async {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
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

      // 401 (u otro error): token inválido/vencido → limpiar sesión.
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
  /// Guarda el JWT devuelto por `/auth/login` y restaura el perfil.
  Future<bool> restaurarSesionLocalDesdeAdmin(String newToken) async {
    await _session.guardarToken(newToken);
    return restaurarSesion();
  }

  /// Inicia sesión con la cuenta de Google del usuario.
  ///
  /// Primero entra con Firebase/Google y luego registra la sesión en el
  /// backend (`POST /auth/google`) mandando el ID Token de Firebase, que el
  /// backend verifica server-side. A cambio guarda el usuario en `usuarios`,
  /// vincula `oauth_cuenta` y devuelve un JWT, que se persiste en
  /// [SessionService].
  ///
  /// Si el backend no responde, se cierra la sesión de Google y se muestra
  /// el error (ya no se cae a demo). Solo si el propio Google falla o el
  /// usuario cancela, y [demoFallback] está activo, se entra a la simulación.
  ///
  /// Retorna `true` si la sesión quedó activa (real o simulada).
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
      if (firebaseUser != null && firebaseUser.email != null) {
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

  /// Envía el ID Token de Firebase al backend para verificar la identidad
  /// y guardar el usuario en la BD.
  ///
  /// Retorna `false` (y deja `_errorMessage` listo) si el servidor no
  /// respondió o rechazó el token.
  Future<bool> _registrarGoogleEnBackend(User firebaseUser) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final usuario =
            (data['usuario'] as Map?)?.cast<String, dynamic>() ?? {};
        _token = data['token'] as String?;
        _backendNombre = (usuario['nombre'] as String?)?.trim();
        _backendApellido = usuario['apellido'] as String?;
        _backendEmail = usuario['correo'] as String?;
        _backendId = usuario['id'] as int? ?? usuario['idUsuario'] as int? ?? usuario['id_usuario'] as int?;
        if (_token != null) {
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
    final GoogleSignIn signIn = GoogleSignIn.instance;
    final GoogleSignInAccount account = await signIn.authenticate();
    final GoogleSignInAuthentication authTokens = account.authentication;
    final credential =
        GoogleAuthProvider.credential(idToken: authTokens.idToken);
    await _auth.signInWithCredential(credential);
  }

  void _limpiarSesionBackend() {
    _token = null;
    _backendNombre = null;
    _backendApellido = null;
    _backendEmail = null;
    _backendId = null;
    _roles = [];
  }

  /// Cierra la sesión (real o simulada) y vuelve al inicio.
  Future<void> signOut() async {
    try {
      if (!_demoMode && !kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {
      // Si no había sesión de Google, ignoramos el error.
    }
    if (!_demoMode) {
      await _auth.signOut();
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

/// Permite exponer [AuthProvider] a todo el árbol sin dependencias externas.
class AuthScope extends InheritedNotifier<AuthProvider> {
  const AuthScope({
    super.key,
    required AuthProvider authProvider,
    required super.child,
  }) : super(notifier: authProvider);

  static AuthProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'Se requiere un AuthScope por encima del widget.');
    return scope!.notifier!;
  }
}
