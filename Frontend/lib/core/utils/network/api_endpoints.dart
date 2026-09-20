import 'package:flutter/foundation.dart';

/// Entornos en los que la app puede correr y su URL base hacia el backend.
enum Environment { emulador, dispositivoFisico, produccion }

/// Configuración centralizada de la URL base hacia el backend NestJS.
///
/// Todos los llamados HTTP deben usar [ApiEndpoints.baseUrl] (y los getters
/// de endpoint), nunca URLs hardcodeadas.
class ApiEndpoints {
  ApiEndpoints._();

  // Cambia este valor manualmente según dónde se esté probando:
  static const Environment currentEnv = Environment.dispositivoFisico;

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      final uri = Uri.parse(configured);
      if (!uri.hasAuthority || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
          (kReleaseMode && uri.scheme != 'https') || !['http', 'https'].contains(uri.scheme)) {
        throw StateError('API_BASE_URL debe ser una URL HTTPS válida en producción');
      }
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    if (kReleaseMode) throw StateError('Falta --dart-define=API_BASE_URL para producción');
    // En web (Chrome corriendo en la misma PC) el navegador alcanza el
    // backend por localhost; los aliases 10.0.2.2 / IP WiFi solo aplican
    // cuando la app corre en un emulador o dispositivo móvil.
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    switch (currentEnv) {
      case Environment.emulador:
        return 'http://10.0.2.2:3000';
      case Environment.dispositivoFisico:
        return 'http://127.0.0.1:3000'; // Usando ADB Reverse (Red Universitaria)
      case Environment.produccion:
        return 'https://tu-dominio-futuro.com';
    }
  }

  static String get authGoogle => '$baseUrl/api/v1/auth/google';
  static String get authPerfil => '$baseUrl/api/v1/auth/perfil';
  static String get authSolicitarRecuperacion => '$baseUrl/api/v1/auth/solicitar-recuperacion';
  static String get authVerificarPinRecuperacion => '$baseUrl/api/v1/auth/verificar-pin-recuperacion';
  static String get authRestablecerPassword => '$baseUrl/api/v1/auth/restablecer-password';
}
