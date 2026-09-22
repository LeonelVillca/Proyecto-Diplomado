import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/admin/auth/auth_response_message.dart';

void main() {
  test('lee mensaje y errores de validación en formatos NestJS', () {
    expect(
      authResponseMessage('{"message":"PIN inválido"}', 'fallback'),
      'PIN inválido',
    );
    expect(
      authResponseMessage(
        '{"message":["Falta correo","PIN inválido"]}',
        'fallback',
      ),
      'Falta correo\nPIN inválido',
    );
  });

  test('usa fallback seguro con cuerpo vacío o no JSON', () {
    expect(authResponseMessage('', 'fallback'), 'fallback');
    expect(authResponseMessage('respuesta inválida', 'fallback'), 'fallback');
  });

  test('no afirma que un correo no se envió ante respuesta 5xx', () {
    expect(
      authHttpErrorMessage(
        500,
        '{"message":"Internal server error"}',
        'fallback',
      ),
      contains('no pudo confirmar la operación'),
    );
  });

  test('explica el límite de solicitudes 429', () {
    expect(authHttpErrorMessage(429, '', 'fallback'), contains('un minuto'));
  });
}
