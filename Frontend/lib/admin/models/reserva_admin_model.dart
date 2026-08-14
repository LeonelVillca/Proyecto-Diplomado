class ReservaAdminModel {
  final int id;
  final String estado;
  final int idUsuario;
  final int idMesa;
  final int idRestaurante;
  final DateTime fechaHora;
  final int cantidadPersonas;
  final String? requerimientosEspeciales;
  final String motivoRechazo;

  ReservaAdminModel({
    required this.id,
    required this.estado,
    required this.idUsuario,
    required this.idMesa,
    required this.idRestaurante,
    required this.fechaHora,
    required this.cantidadPersonas,
    this.requerimientosEspeciales,
    required this.motivoRechazo,
  });

  factory ReservaAdminModel.fromJson(Map<String, dynamic> json) {
    return ReservaAdminModel(
      id: json['id'],
      estado: json['estado'] ?? 'pendiente',
      idUsuario: json['usuario']?['id'] ?? 0,
      idMesa: json['mesa']?['id'] ?? 0,
      idRestaurante: json['restaurante']?['id'] ?? 0,
      fechaHora: DateTime.parse(json['fechaHora']),
      cantidadPersonas: json['cantidadPersonas'] ?? 1,
      requerimientosEspeciales: json['requerimientosEspeciales'],
      motivoRechazo: json['motivoRechazo'] ?? '',
    );
  }
}
