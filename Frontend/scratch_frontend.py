import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Models
model_content = """class MenuAdminModel {
  final int id;
  final int idRestaurante;
  final String nombre;
  final String tipo;
  final bool disponibilidad;
  final List<PlatoAdminModel> platos;

  MenuAdminModel({
    required this.id,
    required this.idRestaurante,
    required this.nombre,
    required this.tipo,
    required this.disponibilidad,
    required this.platos,
  });

  factory MenuAdminModel.fromJson(Map<String, dynamic> json) {
    return MenuAdminModel(
      id: json['id'] ?? json['id_menu'] ?? 0,
      idRestaurante: json['idRestaurante'] ?? json['id_restaurante'] ?? 0,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      disponibilidad: json['disponibilidad'] ?? true,
      platos: (json['platos'] as List<dynamic>?)
              ?.map((p) => PlatoAdminModel.fromJson(p))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idRestaurante': idRestaurante,
      'nombre': nombre,
      'tipo': tipo,
      'disponibilidad': disponibilidad,
      'platos': platos.map((p) => p.toJson()).toList(),
    };
  }
}

class PlatoAdminModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? fotoUrl;
  final bool disponible;

  PlatoAdminModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.fotoUrl,
    required this.disponible,
  });

  factory PlatoAdminModel.fromJson(Map<String, dynamic> json) {
    return PlatoAdminModel(
      id: json['id'] ?? json['id_plato'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio'] != null ? double.parse(json['precio'].toString()) : 0.0,
      fotoUrl: json['foto_url'] ?? json['fotoUrl'],
      disponible: json['disponible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'fotoUrl': fotoUrl,
      'disponible': disponible,
    };
  }
}
"""

# 2. Services
service_content = """import 'import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/network/api_endpoints.dart';
import '../models/menu_admin_model.dart';
import 'package:http_parser/http_parser.dart';

class MenuAdminService {
  final String _token;
  MenuAdminService(this._token);

  Future<int?> obtenerIdRestaurante() async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
    final res = await http.get(url, headers: {'Authorization': 'Bearer \\$_token'});
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data.isNotEmpty) {
        return data.first['id'];
      }
    }
    return null;
  }

  Future<List<MenuAdminModel>> obtenerMenus(int idRestaurante) async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/menu/restaurante/\\$idRestaurante');
    final res = await http.get(url, headers: {'Authorization': 'Bearer \\$_token'});
    
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => MenuAdminModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener menús: \\${res.body}');
  }

  Future<MenuAdminModel> crearMenu(Map<String, dynamic> data) async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/menu');
    final res = await http.post(
      url, 
      headers: {'Authorization': 'Bearer \\$_token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return MenuAdminModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Error al crear menú: \\${res.body}');
  }

  Future<MenuAdminModel> actualizarMenu(int idMenu, Map<String, dynamic> data) async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/menu/\\$idMenu');
    final res = await http.patch(
      url, 
      headers: {'Authorization': 'Bearer \\$_token', 'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return MenuAdminModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    throw Exception('Error al actualizar menú: \\${res.body}');
  }

  Future<void> cambiarDisponibilidad(int idMenu, bool disponibilidad) async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/menu/\\$idMenu/disponibilidad');
    final res = await http.patch(
      url, 
      headers: {'Authorization': 'Bearer \\$_token', 'Content-Type': 'application/json'},
      body: jsonEncode({'disponibilidad': disponibilidad}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al cambiar disponibilidad: \\${res.body}');
    }
  }

  Future<String> subirFotoPlato(Uint8List bytes, String filename, int idRestaurante) async {
    final url = Uri.parse('\\${ApiEndpoints.baseUrl}/api/v1/plato/upload-foto');
    final req = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer \\$_token'
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
    throw Exception('Error al subir foto: \\$body');
  }
}
"""

write_file('d:/Proyecto_Diplomado/Frontend/lib/admin/models/menu_admin_model.dart', model_content)
write_file('d:/Proyecto_Diplomado/Frontend/lib/admin/services/menu_admin_service.dart', service_content)
