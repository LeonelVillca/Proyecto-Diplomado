import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:http_parser/http_parser.dart';

class MenuAdminService {
  final String _token;
  MenuAdminService(this._token);

  Future<int?> obtenerIdRestaurante() async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
    final res = await http.get(url, headers: {'Authorization': 'Bearer $_token'});
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data.isNotEmpty) {
        return data.first['id'];
      }
    }
    return null;
  }

  Future<List<MenuAdminModel>> obtenerMenus(int idRestaurante) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/restaurante/$idRestaurante');
    final res = await http.get(url, headers: {'Authorization': 'Bearer $_token'});
    
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => MenuAdminModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener menús: ${res.body}');
  }

  Future<MenuAdminModel> crearMenu(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu');
    final res = await http.post(
      url, 
      headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return MenuAdminModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Error al crear menú: ${res.body}');
  }

  Future<MenuAdminModel> actualizarMenu(int idMenu, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/$idMenu');
    final res = await http.patch(
      url, 
      headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return MenuAdminModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Error al actualizar menú: ${res.body}');
  }

  Future<void> cambiarDisponibilidad(int idMenu, bool disponibilidad) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/$idMenu/disponibilidad');
    final res = await http.patch(
      url, 
      headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
      body: jsonEncode({'disponibilidad': disponibilidad}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al cambiar disponibilidad: ${res.body}');
    }
  }

  Future<String> subirFotoPlato(Uint8List bytes, String filename, int idRestaurante) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/plato/upload-foto');
    final req = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['idRestaurante'] = idRestaurante.toString()
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = jsonDecode(body);
      return json['url'];
    }
    throw Exception('Error al subir foto: $body');
  }
}
