import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/services/shared/secure_http.dart';

void main() {
  tearDown(() { SessionHttp.tokenProvider = null; SessionHttp.onUnauthorized = null; });
  test('reemplaza el JWT viejo con la sesión vigente y desactiva redirecciones', () async {
    SessionHttp.tokenProvider = () async => 'renewed-token';
    final req = http.Request('GET', Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante'));
    req.headers['Authorization'] = 'Bearer old-token';
    expect(await SessionHttp.authorize(req), 'renewed-token');
    expect(req.headers['authorization'], 'Bearer renewed-token');
    expect(req.followRedirects, isFalse);
  });
  test('no envía credenciales a otro servidor', () async {
    SessionHttp.tokenProvider = () async => 'secret';
    final req = http.Request('GET', Uri.parse('https://external.example.test'));
    req.headers['Authorization'] = 'Bearer old';
    await expectLater(SessionHttp.authorize(req), throwsStateError);
  });
  test('permite petición pública sin añadir el token', () async {
    SessionHttp.tokenProvider = () async => 'secret';
    final req = http.Request('GET', Uri.parse('https://external.example.test'));
    expect(await SessionHttp.authorize(req), isNull);
    expect(req.headers.containsKey('authorization'), isFalse);
  });
  test('bloquea peticiones protegidas sin sesión', () async {
    SessionHttp.tokenProvider = () async => null;
    final req = http.Request('POST', Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas'));
    req.headers['Authorization'] = 'Bearer expired';
    await expectLater(SessionHttp.authorize(req), throwsStateError);
  });
  test('invalida solo ante 401, no ante fallos del servidor', () async {
    final invalidated = <String>[];
    SessionHttp.onUnauthorized = (token) async { invalidated.add(token); };
    await SessionHttp.check(500, 'token');
    expect(invalidated, isEmpty);
    await SessionHttp.check(401, 'token');
    expect(invalidated, ['token']);
  });
}
