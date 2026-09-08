class UsuarioAdminModel {
  final int id;
  final String nombre;
  final String? apellido;
  final String correo;
  final String estado;
  final String fechaRegistro;
  final bool esLocal;
  final bool esExterno;

  UsuarioAdminModel({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.correo,
    required this.estado,
    required this.fechaRegistro,
    this.esLocal = false,
    this.esExterno = false,
  });

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      apellido: json['apellido'],
      correo: json['correo'] ?? 'Sin correo',
      estado: json['estado'] ?? 'inactivo',
      fechaRegistro: json['fechaRegistro'] ?? '',
      esLocal: json['esLocal'] == true,
      esExterno: json['esExterno'] == true,
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

class PermisoModel {
  final int id;
  final String modulo;
  final String accion;
  final String? descripcion;

  PermisoModel({
    required this.id,
    required this.modulo,
    required this.accion,
    this.descripcion,
  });

  factory PermisoModel.fromJson(Map<String, dynamic> json) {
    return PermisoModel(
      id: json['id'],
      modulo: json['modulo'] ?? 'General',
      accion: json['accion'] ?? 'Sin acción',
      descripcion: json['descripcion'],
    );
  }
}
