import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/admin/auth/password_policy.dart';

void main() {
  group('PasswordPolicy', () {
    test('acepta contraseña con mínimo y complejidad requerida', () {
      expect(PasswordPolicy.isStrong('Chapaca2026'), isTrue);
      expect(PasswordPolicy.validate('Chapaca2026'), isNull);
    });

    test('explica requisito de longitud', () {
      expect(PasswordPolicy.validate('Ab1'), 'Usa al menos 8 caracteres.');
    });

    test('exige mayúscula, minúscula y número o símbolo', () {
      expect(PasswordPolicy.validate('chapaca2026'), contains('mayúscula'));
      expect(PasswordPolicy.validate('CHAPACA2026'), contains('minúscula'));
      expect(
        PasswordPolicy.validate('Chapacaweb'),
        contains('número o un símbolo'),
      );
      expect(PasswordPolicy.validate('Chapaca!web'), isNull);
    });

    test('valida confirmación vacía y distinta', () {
      expect(
        PasswordPolicy.validateConfirmation('Chapaca2026', ''),
        'Confirma tu contraseña.',
      );
      expect(
        PasswordPolicy.validateConfirmation('Chapaca2026', 'Otra2026'),
        'Las contraseñas no coinciden.',
      );
      expect(
        PasswordPolicy.validateConfirmation('Chapaca2026', 'Chapaca2026'),
        isNull,
      );
    });
  });
}
