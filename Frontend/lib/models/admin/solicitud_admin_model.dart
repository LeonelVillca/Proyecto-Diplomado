class SolicitudAdminModel {
  final int id;
  final String nombreRestaurante;
  final String celularContacto;
  final String? descripcion;
  final String estado;
  final bool correoVerificado;
  final String fechaSolicitud;
  final String? fechaRevision;
  final String? motivoRechazo;
  final String? nitNegocio;
  final List<dynamic>? documentosAdjuntos;
  final Map<String, dynamic>? usuario;

  SolicitudAdminModel({
    required this.id,
    required this.nombreRestaurante,
    required this.celularContacto,
    this.descripcion,
    required this.estado,
    required this.correoVerificado,
    required this.fechaSolicitud,
    this.fechaRevision,
    this.motivoRechazo,
    this.nitNegocio,
    this.documentosAdjuntos,
    this.usuario,
  });

  factory SolicitudAdminModel.fromJson(Map<String, dynamic> json) {
    return SolicitudAdminModel(
      id: json['id'],
      nombreRestaurante: json['nombreRestaurante'],
      celularContacto: json['celularContacto'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'pendiente',
      correoVerificado: json['correoVerificadoAt'] != null,
      fechaSolicitud: json['fecha'] ?? '',
      fechaRevision: json['fechaRevision'],
      motivoRechazo: json['motivoRechazo'],
      nitNegocio: json['nitNegocio'],
      documentosAdjuntos: json['documentosAdjuntos'],
      usuario: json['usuario'],
    );
  }
}
