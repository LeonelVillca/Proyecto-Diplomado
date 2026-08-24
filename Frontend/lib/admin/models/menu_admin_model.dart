class MenuAdminModel {
  final int id;
  final int idRestaurante;
  final String nombre;
  final String tipo;
  final bool disponibilidad;
  final List<PlatoAdminModel> platos;

  MenuAdminModel({
    required this.id,
    required this.idRestaurante,
    required this.nombre,
    required this.tipo,
    required this.disponibilidad,
    required this.platos,
  });

  factory MenuAdminModel.fromJson(Map<String, dynamic> json) {
    return MenuAdminModel(
      id: json['id'] ?? json['id_menu'] ?? 0,
      idRestaurante: json['idRestaurante'] ?? json['id_restaurante'] ?? 0,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      disponibilidad: json['disponibilidad'] ?? true,
      platos: (json['platos'] as List<dynamic>?)
              ?.map((p) => PlatoAdminModel.fromJson(p))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idRestaurante': idRestaurante,
      'nombre': nombre,
      'tipo': tipo,
      'disponibilidad': disponibilidad,
      'platos': platos.map((p) => p.toJson()).toList(),
    };
  }
}

class PlatoAdminModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? fotoUrl;
  final bool disponible;

  PlatoAdminModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.fotoUrl,
    required this.disponible,
  });

  factory PlatoAdminModel.fromJson(Map<String, dynamic> json) {
    return PlatoAdminModel(
      id: json['id'] ?? json['id_plato'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio'] != null ? double.parse(json['precio'].toString()) : 0.0,
      fotoUrl: json['foto_url'] ?? json['fotoUrl'],
      disponible: json['disponible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'fotoUrl': fotoUrl,
      'disponible': disponible,
    };
  }
}
