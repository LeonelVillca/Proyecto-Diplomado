import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/usuario_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class RolesCrudScreen extends StatefulWidget {
  const RolesCrudScreen({super.key});

  @override
  State<RolesCrudScreen> createState() => _RolesCrudScreenState();
}

class _RolesCrudScreenState extends State<RolesCrudScreen> {
  bool _isLoading = true;
  List<RolModel> _roles = [];

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    final token = AuthScope.of(context, listen: false).token;
    try {
      final res = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() => _roles = data.map((e) => RolModel.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint('Error fetchRoles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarModalRol({RolModel? rol}) {
    final isEditing = rol != null;
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: rol?.nombre ?? '');
    final descCtrl = TextEditingController(text: rol?.descripcion ?? '');

    AdminModal.show(
      context: context,
      title: isEditing ? 'Editar Rol' : 'Nuevo Rol',
      width: 450,
      confirmText: 'Guardar',
      onConfirm: () async {
        if (formKey.currentState!.validate()) {
          final token = AuthScope.of(context, listen: false).token;
          final uri = isEditing 
              ? Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles/${rol.id}')
              : Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles');
              
          try {
            final res = isEditing
                ? await http.patch(
                    uri,
                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                    body: jsonEncode({'nombre': nombreCtrl.text, 'descripcion': descCtrl.text}),
                  )
                : await http.post(
                    uri,
                    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                    body: jsonEncode({'nombre': nombreCtrl.text, 'descripcion': descCtrl.text}),
                  );

            if (res.statusCode == 200 || res.statusCode == 201) {
              Navigator.pop(context);
              _cargarRoles();
              AdminNotificationModal.success(context, isEditing ? 'Rol actualizado' : 'Rol creado');
            } else {
              AdminNotificationModal.error(context, 'No pudimos guardar el rol.');
            }
          } catch (e) {
            AdminNotificationModal.error(context, 'Error de conexión. Inténtalo nuevamente.');
          }
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del Rol',
                hintText: 'ej. cajero_restaurante',
                prefixIcon: const Icon(Icons.badge_rounded, color: AdminTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Breve descripción de los permisos...',
                prefixIcon: const Icon(Icons.description_rounded, color: AdminTheme.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarRol(RolModel rol) {
    AdminModal.show(
      context: context,
      title: 'Eliminar Rol',
      width: 400,
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
      onConfirm: () async {
        final token = AuthScope.of(context, listen: false).token;
        try {
          final res = await http.delete(
            Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles/${rol.id}'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (res.statusCode == 200 || res.statusCode == 204) {
            Navigator.pop(context);
            _cargarRoles();
            AdminNotificationModal.success(context, 'Rol eliminado correctamente');
          } else {
            AdminNotificationModal.error(context, 'No pudimos eliminar el rol.');
          }
        } catch (e) {
          AdminNotificationModal.error(context, 'Error de conexión. Inténtalo nuevamente.');
        }
      },
      content: Text(
        '¿Estás seguro de eliminar el rol "${rol.nombre}"? Esta acción no se puede deshacer y puede afectar a los usuarios asignados.',
        style: GoogleFonts.inter(color: AdminTheme.textDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            kicker: 'SISTEMA',
            titleBefore: 'Gestión de ',
            titleEmphasis: 'Roles',
            description: 'Crea y administra los roles disponibles en el sistema.',
            actions: [
              FilledButton.icon(
                onPressed: () => _mostrarModalRol(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo rol'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                : AdminSurface(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _roles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AdminTheme.border),
                      itemBuilder: (context, i) {
                        final rol = _roles[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security_rounded, color: AdminTheme.primaryColor, size: 22),
                          ),
                          title: Text(rol.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AdminTheme.textDark)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(rol.descripcion ?? 'Sin descripción', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 13)),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AdminTheme.textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'edit') _mostrarModalRol(rol: rol);
                              if (value == 'delete') _eliminarRol(rol);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_rounded, size: 18, color: AdminTheme.textMuted),
                                    const SizedBox(width: 12),
                                    Text('Editar', style: GoogleFonts.inter(color: AdminTheme.textDark)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                    const SizedBox(width: 12),
                                    Text('Eliminar', style: GoogleFonts.inter(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
