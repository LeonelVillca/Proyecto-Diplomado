import 'package:frontend/core/utils/network/api_endpoints.dart';

/// Configuración de red hacia el backend de Mesa Chapaca (NestJS).
///
/// [ApiConfig] es un alias de compatibilidad: la fuente única de verdad de
/// la URL base es [ApiEndpoints] (ver `lib/core/network/api_endpoints.dart`).
///
/// El backend corre con el prefijo global `/api/v1` y escucha en `0.0.0.0`
/// para ser accesible desde el dispositivo físico. Para cambiar de entorno
/// (emulador, teléfono físico o producción) solo se ajusta
/// `ApiEndpoints.currentEnv`.
class ApiConfig {
  ApiConfig._();

  /// URL base del backend según el entorno configurado.
  static String get baseUrl => ApiEndpoints.baseUrl;

  static String get authRegister => ApiEndpoints.authRegister;
  static String get authGoogle => ApiEndpoints.authGoogle;
  static String get authPerfil => ApiEndpoints.authPerfil;
}