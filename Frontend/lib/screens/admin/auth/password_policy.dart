class PasswordPolicy {
  const PasswordPolicy._();

  static bool hasMinimumLength(String value) => value.length >= 8;

  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool hasNumberOrSymbol(String value) =>
      RegExp(r'[\d\W]').hasMatch(value);

  static bool isStrong(String value) =>
      hasMinimumLength(value) &&
      hasUppercase(value) &&
      hasLowercase(value) &&
      hasNumberOrSymbol(value);

  static String? validate(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Escribe una contraseña.';
    if (!hasMinimumLength(password)) {
      return 'Usa al menos 8 caracteres.';
    }
    if (!hasUppercase(password) || !hasLowercase(password)) {
      return 'Incluye al menos una mayúscula y una minúscula.';
    }
    if (!hasNumberOrSymbol(password)) {
      return 'Incluye al menos un número o un símbolo.';
    }
    return null;
  }

  static String? validateConfirmation(String password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (confirmation != password) return 'Las contraseñas no coinciden.';
    return null;
  }
}
