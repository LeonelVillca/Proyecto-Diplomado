import 'dart:convert';

String authResponseMessage(String body, String fallback) {
  if (body.trim().isEmpty) return fallback;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ?? decoded['mensaje'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((item) => item.toString()).join('\n');
      }
    }
  } on FormatException {
    // Algunas respuestas intermedias no son JSON; conserva el mensaje seguro.
  }
  return fallback;
}

String authHttpErrorMessage(int status, String body, String fallback) {
  if (status == 429) {
    return authResponseMessage(
      body,
      'Has solicitado varios códigos. Espera un minuto antes de intentarlo otra vez.',
    );
  }
  if (status >= 500) {
    return 'El servidor no pudo confirmar el resultado. Comprueba si la operación se completó antes de volver a intentarlo.';
  }
  return authResponseMessage(body, fallback);
}
