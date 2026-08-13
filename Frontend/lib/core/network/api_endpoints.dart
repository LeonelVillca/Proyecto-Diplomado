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
  static const Environment currentEnv = Environment.emulador;

  static String get baseUrl {
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
        return 'http://10.110.17.153:3000'; // IP WiFi actual de la PC
      case Environment.produccion:
        return 'https://tu-dominio-futuro.com';
    }
  }

  static String get authLogin => '$baseUrl/api/v1/auth/login';
  static String get authRegister => '$baseUrl/api/v1/auth/register';
  static String get authGoogle => '$baseUrl/api/v1/auth/google';
  static String get authPerfil => '$baseUrl/api/v1/auth/perfil';
}