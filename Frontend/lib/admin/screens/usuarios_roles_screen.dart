import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/usuario_admin_model.dart';

class UsuariosRolesScreen extends StatefulWidget {
  const UsuariosRolesScreen({super.key});

  @override
  State<UsuariosRolesScreen> createState() => _UsuariosRolesScreenState();
}

class _UsuariosRolesScreenState extends State<UsuariosRolesScreen> {
  bool _isLoading = true;
  List<UsuarioAdminModel> _usuarios = [];
  List<RolModel> _rolesDisponibles = [];
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatosIniciales();
      _isInit = false;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final token = AuthScope.of(context).token;
      
      // 1. Cargar Usuarios
      final urlUsuarios = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuarios');
      final resUsuarios = await http.get(urlUsuarios, headers: {'Authorization': 'Bearer $token'});
      
      // 2. Cargar Roles
      final urlRoles = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles');
      final resRoles = await http.get(urlRoles, headers: {'Authorization': 'Bearer $token'});

      if (resUsuarios.statusCode == 200 && resRoles.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(utf8.decode(resUsuarios.bodyBytes));
        final List<dynamic> rolesData = jsonDecode(utf8.decode(resRoles.bodyBytes));
        
        setState(() {
          _usuarios = usersData.map((e) => UsuarioAdminModel.fromJson(e)).toList();
          _rolesDisponibles = rolesData.map((e) => RolModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuarios/roles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _administrarRoles(UsuarioAdminModel usuario) async {
    final token = AuthScope.of(context).token;
    
    // 1. Obtener roles actuales del usuario
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol/usuario/${usuario.id}');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (!mounted) return;
      Navigator.pop(context); // cerrar loader

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        // data es una lista de objetos UsuarioRol donde { idRol: X, rol: { ... } }
        // Simplificamos obteniendo la lista de IDs de roles que ya tiene el usuario.
        final Set<int> rolesActuales = data.map<int>((ur) {
          return (ur['rol']?['id'] as int?) ?? ur['idRol'] as int;
        }).toSet();

        if (mounted) {
          _mostrarModalRoles(usuario, rolesActuales);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error: $e');
    }
  }

  void _mostrarModalRoles(UsuarioAdminModel usuario, Set<int> rolesAsignados) {
    // Variable local para manejar estado de los checkboxes sin redibujar toda la pantalla
    Set<int> rolesModificados = Set.from(rolesAsignados);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: Text(
                'Roles: ${usuario.nombre} ${usuario.apellido ?? ''}'.trim(),
                style: const TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _rolesDisponibles.map((rol) {
                    final hasRole = rolesModificados.contains(rol.id);
                    return CheckboxListTile(
                      title: Text(rol.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla')),
                      subtitle: Text(rol.descripcion ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      activeColor: const Color(0xFF6B1A35),
                      value: hasRole,
                      onChanged: (val) {
                        setStateModal(() {
                          if (val == true) {
                            rolesModificados.add(rol.id);
                          } else {
                            rolesModificados.remove(rol.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _guardarRoles(usuario.id, rolesAsignados, rolesModificados);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _guardarRoles(int idUsuario, Set<int> rolesViejos, Set<int> rolesNuevos) async {
    final token = AuthScope.of(context).token;
    
    final rolesParaAgregar = rolesNuevos.difference(rolesViejos);
    final rolesParaQuitar = rolesViejos.difference(rolesNuevos);

    try {
      // 1. Agregar nuevos
      for (final idRol in rolesParaAgregar) {
        await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'idUsuario': idUsuario, 'idRol': idRol}),
        );
      }
      // 2. Quitar removidos
      for (final idRol in rolesParaQuitar) {
        await http.delete(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol/usuario/$idUsuario/rol/$idRol'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roles actualizados correctamente')));
      }
    } catch (e) {
      debugPrint('Error actualizando roles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Usuarios y Roles',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona los accesos y permisos administrativos de la plataforma.',
          style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _usuarios.isEmpty
                  ? Center(child: Text('No se encontraron usuarios', style: TextStyle(fontFamily: 'Karla', color: Colors.grey.shade500)))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: _usuarios.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final user = _usuarios[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: const Color(0xFF6B1A35),
                              child: Text(user.nombre[0].toUpperCase()),
                            ),
                            title: Text(
                              '${user.nombre} ${user.apellido ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Karla', fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Text(
                              user.correo,
                              style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Karla', fontSize: 13),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () => _administrarRoles(user),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B1A35),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('Editar Roles', style: TextStyle(fontFamily: 'Karla', fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
