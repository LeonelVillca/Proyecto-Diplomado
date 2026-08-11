import 'package:flutter/foundation.dart';

/// Configuración de red hacia el backend de Mesa Chapaca (NestJS).
///
/// El backend corre en `http://localhost:3000` con el prefijo global
/// `/api/v1`, pero el destino varía según dónde corra la app:
///
/// - **PC / Web**: `http://localhost:3000` (misma máquina).
/// - **Emulador Android**: `http://10.0.2.2:3000` (alias del host).
/// - **Teléfono físico por USB**: usa `adb reverse tcp:3000 tcp:3000` y la
///   app se conecta a `http://127.0.0.1:3000` (loopback del dispositivo,
///   redirigido por el túnel hacia el host).
/// - **Teléfono físico por Wi-Fi**: debe pasarse la IP local del PC en la red
///   Wi-Fi al momento de compilar:
///
///   ```sh
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
///   ```
class ApiConfig {
  ApiConfig._();

  /// Sobrescritura aportada en tiempo de compilación con `--dart-define`.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:3000';
    }
    return 'http://localhost:3000';
  }

  static String get authLogin => '$baseUrl/api/v1/auth/login';
  static String get authRegister => '$baseUrl/api/v1/auth/register';
  static String get authGoogle => '$baseUrl/api/v1/auth/google';
  static String get authPerfil => '$baseUrl/api/v1/auth/perfil';
}