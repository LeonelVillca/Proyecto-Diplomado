class SoporteAdminModel {
  final int id;
  final String asunto;
  final String? descripcion;
  final String estado;
  final String? respuesta;
  final String fechaCreacion;
  final String? fechaRespuesta;
  final Map<String, dynamic>? categoriaSoporte;
  final Map<String, dynamic>? usuario;

  SoporteAdminModel({
    required this.id,
    required this.asunto,
    this.descripcion,
    required this.estado,
    this.respuesta,
    required this.fechaCreacion,
    this.fechaRespuesta,
    this.categoriaSoporte,
    this.usuario,
  });

  factory SoporteAdminModel.fromJson(Map<String, dynamic> json) {
    return SoporteAdminModel(
      id: json['idSoporte'] ?? json['id'] ?? 0,
      asunto: json['asunto'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'pendiente',
      respuesta: json['respuesta'],
      fechaCreacion: json['fechaCreacion'] ?? json['fecha_creacion'] ?? '',
      fechaRespuesta: json['fechaRespuesta'] ?? json['fecha_respuesta'],
      categoriaSoporte: json['categoriaSoporte'] ?? json['categoria_soporte'],
      usuario: json['usuario'],
    );
  }
}
