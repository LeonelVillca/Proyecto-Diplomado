import 'dart:convert';
import 'package:http/http.dart' as base;
import 'package:frontend/core/utils/network/api_endpoints.dart';
export 'package:http/http.dart' hide get, post, patch, put, delete, MultipartRequest;

/// Puente de sesión usado por las peticiones existentes, incluyendo multipart.
class SessionHttp {
  static Future<String?> Function()? tokenProvider;
  static Future<void> Function(String token)? onUnauthorized;

  static Future<String?> authorize(base.BaseRequest request) async {
    if (!request.headers.containsKey('authorization')) return null;
    if (request.url.origin != Uri.parse(ApiEndpoints.baseUrl).origin) {
      throw StateError('No se permite enviar credenciales a un servidor externo');
    }
    final token = await tokenProvider?.call();
    if (token == null) throw StateError('La sesión ha expirado. Inicia sesión nuevamente.');
    request.headers['authorization'] = 'Bearer $token';
    request.followRedirects = false;
    return token;
  }

  static Future<void> check(int status, String? token) async {
    if (status == 401 && token != null) await onUnauthorized?.call(token);
  }
}

// Evita que varios taps sobre el mismo botón creen varias peticiones idénticas
// mientras la primera todavía está en curso. Las peticiones diferentes siguen
// siendo independientes.
final Map<String, Future<base.Response>> _inFlightRequests = {};

String _requestKey(String method, Uri url, Map<String, String>? headers, Object? body) {
  final safeHeaders = (headers ?? {}).entries
      .where((entry) => entry.key.toLowerCase() != 'authorization')
      .map((entry) => '${entry.key}:${entry.value}')
      .join('|');
  return '$method|$url|$safeHeaders|${body ?? ''}';
}

Future<base.Response> _request(String method, Uri url, Map<String, String>? headers, Object? body, Encoding? encoding, {Duration? timeout}) async {
  final key = _requestKey(method, url, headers, body);
  final existing = _inFlightRequests[key];
  if (existing != null) return existing;
  final pending = _performRequest(method, url, headers, body, encoding, timeout: timeout);
  _inFlightRequests[key] = pending;
  try {
    return await pending;
  } finally {
    if (identical(_inFlightRequests[key], pending)) _inFlightRequests.remove(key);
  }
}

Future<base.Response> _performRequest(String method, Uri url, Map<String, String>? headers, Object? body, Encoding? encoding, {Duration? timeout}) async {
  final request = base.Request(method, url);
  if (headers != null) request.headers.addAll(headers);
  if (encoding != null) request.encoding = encoding;
  if (body is String) { request.body = body; }
  else if (body is List<int>) { request.bodyBytes = body; }
  else if (body is Map<String, String>) { request.bodyFields = body; }
  else if (body != null) { throw ArgumentError('Formato de petición inválido'); }
  final token = await SessionHttp.authorize(request);
  final client = base.Client();
  try {
    final requestTimeout = timeout ?? const Duration(seconds: 20);
    final response = await base.Response.fromStream(await client.send(request).timeout(requestTimeout))
      .timeout(requestTimeout);
    await SessionHttp.check(response.statusCode, token);
    return response;
  } finally { client.close(); }
}

Future<base.Response> get(Uri url, {Map<String, String>? headers, Duration? timeout}) => _request('GET', url, headers, null, null, timeout: timeout);
Future<base.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding, Duration? timeout}) => _request('POST', url, headers, body, encoding, timeout: timeout);
Future<base.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding, Duration? timeout}) => _request('PATCH', url, headers, body, encoding, timeout: timeout);
Future<base.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding, Duration? timeout}) => _request('PUT', url, headers, body, encoding, timeout: timeout);
Future<base.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding, Duration? timeout}) => _request('DELETE', url, headers, body, encoding, timeout: timeout);

class MultipartRequest extends base.MultipartRequest {
  MultipartRequest(super.method, super.url);
  @override
  Future<base.StreamedResponse> send() async {
    final token = await SessionHttp.authorize(this);
    final client = base.Client();
    try {
      final result = await client.send(this).timeout(const Duration(seconds: 30));
      // Consumir con límite de tiempo también cierra el cliente ante transferencias incompletas.
      final bytes = await result.stream.toBytes().timeout(const Duration(seconds: 30));
      await SessionHttp.check(result.statusCode, token);
      return base.StreamedResponse(Stream.value(bytes), result.statusCode, headers: result.headers, reasonPhrase: result.reasonPhrase);
    } finally { client.close(); }
  }
}
