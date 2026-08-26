class PerfilRestauranteModel {
  final int id;
  final String nombre;
  final String? tipoComida;
  final String? descripcion;
  final String? telefono;
  final String? correo;
  final String? fotoPortada;
  final String? logo;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final bool estado;
  final List<dynamic>? horarios;
  final List<dynamic>? mesas;
  final List<dynamic>? imagenes;

  PerfilRestauranteModel({
    required this.id,
    required this.nombre,
    this.tipoComida,
    this.descripcion,
    this.telefono,
    this.correo,
    this.fotoPortada,
    this.logo,
    this.direccion,
    this.latitud,
    this.longitud,
    required this.estado,
    this.horarios,
    this.mesas,
    this.imagenes,
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
      logo: json['logo'],
      direccion: json['direccion'],
      latitud: json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud: json['longitud'] != null ? (json['longitud'] as num).toDouble() : null,
      estado: json['estado'] ?? false,
      horarios: json['horarios'] ?? [],
      mesas: json['mesas'] ?? [],
      imagenes: json['imagenes'] ?? [],
    );
  }
}
