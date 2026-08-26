class ResenaAdminModel {
  final int id;
  final String? comentario;
  final int calificacion;
  final String fecha;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? restaurante;

  ResenaAdminModel({
    required this.id,
    this.comentario,
    required this.calificacion,
    required this.fecha,
    this.usuario,
    this.restaurante,
  });

  factory ResenaAdminModel.fromJson(Map<String, dynamic> json) {
    return ResenaAdminModel(
      id: json['id'],
      comentario: json['comentario'],
      calificacion: json['calificacion'] ?? 0,
      fecha: json['fecha'] ?? '',
      usuario: json['usuario'],
      restaurante: json['restaurante'],
    );
  }
}
