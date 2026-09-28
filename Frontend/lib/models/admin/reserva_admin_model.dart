import 'package:frontend/core/utils/network/api_endpoints.dart';

class ReservaAdminModel {
  final int id;
  final String estado;
  final int idUsuario;
  final int idMesa;
  final int idRestaurante;
  final String restauranteNombre;
  final DateTime fechaHora;
  final int cantidadPersonas;
  final String? requerimientosEspeciales;
  final String? restauranteFoto;
  final String? restauranteLogo;
  final String? numeroMesa;

  ReservaAdminModel({
    required this.id,
    required this.estado,
    required this.idUsuario,
    required this.idMesa,
    required this.idRestaurante,
    required this.restauranteNombre,
    required this.fechaHora,
    required this.cantidadPersonas,
    this.requerimientosEspeciales,
    this.restauranteFoto,
    this.restauranteLogo,
    this.numeroMesa,
  });

  factory ReservaAdminModel.fromJson(Map<String, dynamic> json) {
    final restaurante = json['mesa']?['restaurante'];

    String? restauranteImageUrl(dynamic value) {
      final path = value?.toString().trim();
      if (path == null || path.isEmpty) return null;
      final uri = Uri.tryParse(path);
      if (uri != null && uri.hasScheme) return path;
      return Uri.parse(ApiEndpoints.baseUrl).resolve(path).toString();
    }

    // Parse fecha and hora into a single DateTime
    DateTime parseFechaHora() {
      try {
        final fecha = json['fecha'] as String;
        final hora = json['hora'] as String;
        return DateTime.parse('${fecha}T$hora');
      } catch (e) {
        return DateTime.now();
      }
    }

    return ReservaAdminModel(
      id: json['id'],
      estado: json['estado'] ?? 'pendiente',
      idUsuario: json['usuario']?['id'] ?? 0,
      idMesa: json['mesa']?['id'] ?? 0,
      idRestaurante: json['mesa']?['restaurante']?['id'] ?? 0,
      restauranteNombre:
          json['mesa']?['restaurante']?['nombre'] ?? 'Restaurante',
      fechaHora: parseFechaHora(),
      cantidadPersonas: json['numeroPersonas'] ?? 1,
      requerimientosEspeciales: json['comentarios'],
      restauranteFoto: restauranteImageUrl(restaurante?['fotoPortada']),
      restauranteLogo: restauranteImageUrl(restaurante?['logo']),
      numeroMesa: json['mesa']?['numeroMesa']?.toString(),
    );
  }
}
