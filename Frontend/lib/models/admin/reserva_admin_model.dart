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
  });

  factory ReservaAdminModel.fromJson(Map<String, dynamic> json) {
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
      restauranteNombre: json['mesa']?['restaurante']?['nombre'] ?? 'Restaurante',
      fechaHora: parseFechaHora(),
      cantidadPersonas: json['numeroPersonas'] ?? 1,
      requerimientosEspeciales: json['comentarios'],
    );
  }
}
