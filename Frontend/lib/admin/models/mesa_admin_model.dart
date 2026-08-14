class MesaAdminModel {
  final int id;
  final String numeroMesa;
  final int capacidad;
  final String estado;

  MesaAdminModel({
    required this.id,
    required this.numeroMesa,
    required this.capacidad,
    required this.estado,
  });

  factory MesaAdminModel.fromJson(Map<String, dynamic> json) {
    return MesaAdminModel(
      id: json['id'],
      numeroMesa: json['numero_mesa'] ?? json['numeroMesa'] ?? '',
      capacidad: json['capacidad'] ?? 1,
      estado: json['estado'] ?? 'libre',
    );
  }
}
