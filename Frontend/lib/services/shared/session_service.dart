import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia segura del JWT del backend en el dispositivo.
///
/// Usa `flutter_secure_storage` (Keystore/Keychain/DPAPI según la
/// plataforma), nunca `shared_preferences` ni variables en memoria, porque
/// el token es la llave de acceso a los endpoints protegidos.
class SessionService {
  SessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'backend_jwt';

  /// Guarda el JWT de la sesión activa.
  Future<void> guardarToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Devuelve el JWT guardado, o `null` si no hay sesión.
  Future<String?> obtenerToken() => _storage.read(key: _tokenKey);

  /// Elimina el JWT (cierre de sesión).
  Future<void> eliminarToken() => _storage.delete(key: _tokenKey);
}
