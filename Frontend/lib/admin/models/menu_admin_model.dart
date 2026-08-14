class MenuAdminModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? tipo;
  final bool disponibilidad;

  MenuAdminModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.tipo,
    required this.disponibilidad,
  });

  factory MenuAdminModel.fromJson(Map<String, dynamic> json) {
    return MenuAdminModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      tipo: json['tipo'],
      disponibilidad: json['disponibilidad'] ?? true,
    );
  }
}
