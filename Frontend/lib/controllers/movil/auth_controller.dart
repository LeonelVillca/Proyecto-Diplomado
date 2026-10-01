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
import 'package:frontend/services/movil/notifications_service.dart';

part 'autenticacion/sesion_google.dart';
part 'autenticacion/renovacion_sesion.dart';
part 'autenticacion/cierre_sesion.dart';

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
    this.demoFallback = false, // Desactivado: errores reales deben ser visibles
    SessionService? session,
  }) : _session = session ?? SessionService() {
    _escucharCambiosFirebase();
    WidgetsBinding.instance.addObserver(this);
    SessionHttp.tokenProvider = validToken;
    SessionHttp.onUnauthorized = invalidateToken;
    _temporizadorRenovacion = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isAuthenticated) unawaited(validToken().catchError((_) => null));
    });
  }

  final FirebaseAuth? _firebaseAuth;

  /// Persistencia segura del JWT del backend.
  final SessionService _session;
  Timer? _temporizadorRenovacion;
  Future<String?>? _renovacionEnCurso;
  StreamSubscription<User?>? _suscripcionCambiosAuth;
  int _generacionSesion = 0;
  bool _disposeRealizado = false;

  /// Si es `true`, los fallos de Google caen a un perfil simulado.
  final bool demoFallback;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  AuthStatus _status = AuthStatus.idle;
  User? _user;
  String? _mensajeError;
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
  String? get errorMessage => _mensajeError;
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

  Map<String, dynamic> _decodificarJwt(String token) {
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

  void _escucharCambiosFirebase() {
    try {
      _suscripcionCambiosAuth = _auth.authStateChanges().listen((firebaseUser) {
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
  Future<bool> restaurarSesion() => _restaurarSesion();

  /// Método especial para el flujo administrativo web (login local).
  Future<bool> restaurarSesionLocalDesdeAdmin(String newToken) async {
    await _session.guardarToken(newToken);
    return restaurarSesion();
  }

  /// Inicia sesión con la cuenta de Google del usuario.
  Future<bool> signInWithGoogle() => _iniciarSesionConGoogle();

  /// Entra manualmente al modo de demostración (útil para maquetas).
  void enterSimulation() => _entrarModoSimulacion();

  Future<String?> validToken() => _obtenerTokenValido();

  Future<void> invalidateToken(String rejected) => _invalidarToken(rejected);

  /// Cierra la sesión (real o simulada) y vuelve al inicio.
  Future<void> signOut() => _cerrarSesion();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAuthenticated)
      unawaited(validToken().catchError((_) => null));
  }

  @override
  void dispose() {
    _disposeRealizado = true;
    _generacionSesion++;
    _temporizadorRenovacion?.cancel();
    _suscripcionCambiosAuth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SessionHttp.tokenProvider = null;
    SessionHttp.onUnauthorized = null;
    super.dispose();
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
