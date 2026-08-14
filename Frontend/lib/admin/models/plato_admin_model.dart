class PlatoAdminModel {
  final int? id;
  final int? idMenu;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? foto;
  final bool disponibilidad;

  PlatoAdminModel({
    this.id,
    this.idMenu,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.foto,
    this.disponibilidad = true,
  });

  factory PlatoAdminModel.fromJson(Map<String, dynamic> json) {
    return PlatoAdminModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      precio: (json['precio'] ?? 0).toDouble(),
      foto: json['foto'],
      disponibilidad: json['disponibilidad'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMenu != null) 'idMenu': idMenu,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'precio': precio,
      if (foto != null) 'foto': foto,
      'disponibilidad': disponibilidad,
    };
  }
}
