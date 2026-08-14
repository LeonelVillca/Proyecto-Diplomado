class PerfilRestauranteModel {
  final int id;
  final String nombre;
  final String? tipoComida;
  final String? descripcion;
  final String? telefono;
  final String? correo;
  final String? fotoPortada;
  final bool estado;

  PerfilRestauranteModel({
    required this.id,
    required this.nombre,
    this.tipoComida,
    this.descripcion,
    this.telefono,
    this.correo,
    this.fotoPortada,
    required this.estado,
  });

  factory PerfilRestauranteModel.fromJson(Map<String, dynamic> json) {
    return PerfilRestauranteModel(
      id: json['id'],
      nombre: json['nombre'],
      tipoComida: json['tipoComida'],
      descripcion: json['descripcion'],
      telefono: json['telefono'],
      correo: json['correo'],
      fotoPortada: json['fotoPortada'],
      estado: json['estado'] ?? false,
    );
  }
}
