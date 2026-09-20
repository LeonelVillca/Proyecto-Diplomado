class RestauranteAdminModel {
  final int id;
  final String nombre;
  final String? tipoComida;
  final String? correo;
  final String? telefono;
  final bool estado;
  final String? solicitudEstado;
  final Map<String, dynamic>? administrador;

  const RestauranteAdminModel({
    required this.id,
    required this.nombre,
    this.tipoComida,
    this.correo,
    this.telefono,
    required this.estado,
    this.solicitudEstado,
    this.administrador,
  });

  factory RestauranteAdminModel.fromJson(Map<String, dynamic> json) {
    return RestauranteAdminModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      tipoComida: json['tipoComida'],
      correo: json['correo'],
      telefono: json['telefono'],
      estado: json['estado'] == true,
      solicitudEstado: json['solicitudEstado'],
      administrador: json['administrador'] is Map
          ? Map<String, dynamic>.from(json['administrador'] as Map)
          : null,
    );
  }
}
