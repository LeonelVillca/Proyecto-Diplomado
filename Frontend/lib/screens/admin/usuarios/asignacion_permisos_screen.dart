import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/usuario_admin_model.dart';
import 'package:frontend/core/admin/theme_admin.dart';

class PermisoModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String codigo;
  
  PermisoModel({required this.id, required this.nombre, this.descripcion, required this.codigo});
  
  factory PermisoModel.fromJson(Map<String, dynamic> json) {
    return PermisoModel(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['descripcion'] ?? json['nombre'] ?? json['codigo'] ?? '',
      descripcion: json['descripcion'],
    );
  }
}

class AsignacionPermisosScreen extends StatefulWidget {
  const AsignacionPermisosScreen({super.key});

  @override
  State<AsignacionPermisosScreen> createState() => _AsignacionPermisosScreenState();
}

class _AsignacionPermisosScreenState extends State<AsignacionPermisosScreen> {
  bool _isLoading = true;
  List<RolModel> _roles = [];
  List<PermisoModel> _permisosDisponibles = [];
  RolModel? _rolSeleccionado;
  Set<int> _permisosAsignados = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final token = AuthScope.of(context, listen: false).token;
      
      final urlRoles = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles');
      final resRoles = await http.get(urlRoles, headers: {'Authorization': 'Bearer $token'});
      
      final urlPermisos = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/permisos');
      final resPermisos = await http.get(urlPermisos, headers: {'Authorization': 'Bearer $token'});

      if (resRoles.statusCode == 200 && resPermisos.statusCode == 200) {
        final List<dynamic> rolesData = jsonDecode(utf8.decode(resRoles.bodyBytes));
        final List<dynamic> permisosData = jsonDecode(utf8.decode(resPermisos.bodyBytes));
        
        setState(() {
          _roles = rolesData.map((e) => RolModel.fromJson(e)).toList();
          _permisosDisponibles = permisosData.map((e) => PermisoModel.fromJson(e)).toList();
          if (_roles.isNotEmpty) {
            _seleccionarRol(_roles.first);
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando roles/permisos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarRol(RolModel rol) async {
    setState(() {
      _rolSeleccionado = rol;
      _permisosAsignados.clear();
    });
    
    final token = AuthScope.of(context, listen: false).token;
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/rol-permiso/rol/${rol.id}');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final Set<int> actuales = data.map<int>((rp) {
          return rp['permiso'] != null ? (rp['permiso']['id'] as int) : (rp['idPermiso'] as int);
        }).toSet();

        if (mounted && _rolSeleccionado?.id == rol.id) {
          setState(() => _permisosAsignados = actuales);
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo permisos de rol: $e');
    }
  }

  Future<void> _togglePermiso(PermisoModel permiso, bool value) async {
    if (_rolSeleccionado == null) return;
    final token = AuthScope.of(context, listen: false).token;
    
    // Optimistic UI update
    setState(() {
      if (value) _permisosAsignados.add(permiso.id);
      else _permisosAsignados.remove(permiso.id);
      _isSaving = true;
    });

    try {
      if (value) {
        await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/rol-permiso'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'idRol': _rolSeleccionado!.id, 'idPermiso': permiso.id}),
        );
      } else {
        await http.delete(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/rol-permiso/rol/${_rolSeleccionado!.id}/permiso/${permiso.id}'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      debugPrint('Error guardando permiso: $e');
      // Revert optimistic update
      setState(() {
        if (value) _permisosAsignados.remove(permiso.id);
        else _permisosAsignados.add(permiso.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar permiso.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignación de Permisos', style: AdminTheme.titleStyle),
          const SizedBox(height: 8),
          Text('Configura los accesos del sistema por cada Rol.', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Roles
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Roles Disponibles', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textDark)),
                        ),
                        const Divider(height: 1, color: AdminTheme.border),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: _roles.length,
                            itemBuilder: (context, i) {
                              final rol = _roles[i];
                              final isSelected = _rolSeleccionado?.id == rol.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected ? Border.all(color: AdminTheme.primaryColor.withOpacity(0.2)) : Border.all(color: Colors.transparent),
                                ),
                                child: Material(
                                  color: isSelected ? AdminTheme.primaryColor.withOpacity(0.06) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    onTap: () => _seleccionarRol(rol),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AdminTheme.primaryColor : AdminTheme.surfaceMuted,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.shield_rounded, size: 20, color: isSelected ? Colors.white : AdminTheme.textMuted),
                                    ),
                                    title: Text(rol.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: isSelected ? AdminTheme.primaryDark : AdminTheme.textDark)),
                                    trailing: isSelected ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AdminTheme.primaryColor) : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Columna Derecha: Permisos
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: _rolSeleccionado == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security_rounded, size: 48, color: AdminTheme.border),
                                const SizedBox(height: 16),
                                Text('Selecciona un rol para configurar sus permisos', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Permisos para: ${_rolSeleccionado!.nombre}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textDark)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.sync_rounded, size: 14, color: Colors.green),
                                            const SizedBox(width: 6),
                                            Text('Guardado automático activado', style: GoogleFonts.inter(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (_isSaving) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.primaryColor)),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AdminTheme.border),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _permisosDisponibles.length,
                                  itemBuilder: (context, i) {
                                    final permiso = _permisosDisponibles[i];
                                    final hasPerm = _permisosAsignados.contains(permiso.id);
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: hasPerm ? Colors.green.withOpacity(0.04) : Colors.white,
                                        border: Border.all(color: hasPerm ? Colors.green.withOpacity(0.3) : AdminTheme.border),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: hasPerm ? [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: SwitchListTile(
                                            activeColor: Colors.white,
                                          activeTrackColor: Colors.green,
                                          inactiveTrackColor: AdminTheme.surfaceMuted,
                                          inactiveThumbColor: AdminTheme.textMuted,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          title: Text(permiso.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: hasPerm ? Colors.green.shade700 : AdminTheme.textDark)),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(permiso.descripcion ?? 'Activa para habilitar esta función', style: GoogleFonts.inter(fontSize: 13, color: AdminTheme.textMuted)),
                                          ),
                                          value: hasPerm,
                                          onChanged: (val) => _togglePermiso(permiso, val),
                                          secondary: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: hasPerm ? Colors.green.withOpacity(0.1) : AdminTheme.surfaceMuted,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              hasPerm ? Icons.check_circle_rounded : Icons.lock_outline_rounded, 
                                              color: hasPerm ? Colors.green : AdminTheme.textMuted,
                                              size: 20,
                                            ),
                                          ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

