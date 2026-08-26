class RespuestaResenaAdminModel {
  final int id;
  final int idResena;
  final int idUsuarioRestaurante;
  final String texto;
  final String fechaRespuesta;

  RespuestaResenaAdminModel({
    required this.id,
    required this.idResena,
    required this.idUsuarioRestaurante,
    required this.texto,
    required this.fechaRespuesta,
  });

  factory RespuestaResenaAdminModel.fromJson(Map<String, dynamic> json) {
    return RespuestaResenaAdminModel(
      id: json['id'],
      idResena: json['resena']?['id'] ?? 0,
      idUsuarioRestaurante: json['usuarioRestaurante']?['id'] ?? 0,
      texto: json['texto'] ?? '',
      fechaRespuesta: json['fechaRespuesta'] ?? '',
    );
  }
}
