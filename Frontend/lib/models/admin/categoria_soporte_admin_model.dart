class CategoriaSoporteAdminModel {
  final int id;
  final String nombre;
  final String? descripcion;

  CategoriaSoporteAdminModel({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory CategoriaSoporteAdminModel.fromJson(Map<String, dynamic> json) {
    return CategoriaSoporteAdminModel(
      id: json['idCategoria'] ?? json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }
}
