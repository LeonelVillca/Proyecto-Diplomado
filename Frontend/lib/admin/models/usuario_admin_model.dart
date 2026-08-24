class UsuarioAdminModel {
  final int id;
  final String nombre;
  final String? apellido;
  final String correo;
  final String estado;
  final String fechaRegistro;

  UsuarioAdminModel({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    required this.estado,
    required this.fechaRegistro,
  });

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
      apellido: json['apellido'],
      correo: json['correo'] ?? 'Sin correo',
      estado: json['estado'] ?? 'inactivo',
      fechaRegistro: json['fechaRegistro'] ?? '',
    );
  }
}

class RolModel {
  final int id;
  final String nombre;
  final String? descripcion;

  RolModel({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'],
    );
  }
}
