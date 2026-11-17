import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/services/shared/session_service.dart';
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'la recuperación de cifrado devuelve sesión vacía y permite guardar una nueva',
    () async {
      var recuperando = true;
      String? guardado;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = (call.arguments as Map).cast<String, dynamic>();
            if (call.method == 'read') {
              if (recuperando) {
                recuperando = false;
                return 'Data has been reset';
              }
              return guardado;
            }
            if (call.method == 'write') {
              guardado = args['value'] as String;
              return null;
            }
            throw StateError('Operación inesperada');
          });
      final session = SessionService();
      expect(await session.obtenerToken(), isNull);
      await session.guardarToken('sesion-nueva-ficticia');
      expect(await session.obtenerToken(), 'sesion-nueva-ficticia');
    },
  );

  test(
    'un fallo nativo de lectura no aborta la restauración ni inicia sesión',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'Exception encountered',
              message: 'read BAD_DECRYPT',
            );
          });
      final auth = AuthController(
        httpClient: MockClient(
          (_) async => throw StateError('No debe llamar a la API'),
        ),
      );
      try {
        expect(await auth.restaurarSesion(), isFalse);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.token, isNull);
        expect(auth.status, AuthStatus.idle);
      } finally {
        auth.dispose();
      }
    },
  );

  test('la sesión guardada válida sigue leyéndose sin cambios', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'jwt-ficticio');
    expect(await SessionService().obtenerToken(), 'jwt-ficticio');
  });
}
