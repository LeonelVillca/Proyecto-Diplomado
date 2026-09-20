import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/restaurante_admin_model.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';

class RestaurantesScreen extends StatefulWidget {
  const RestaurantesScreen({super.key});

  @override
  State<RestaurantesScreen> createState() => _RestaurantesScreenState();
}

class _RestaurantesScreenState extends State<RestaurantesScreen> {
  bool _cargando = true;
  List<RestauranteAdminModel> _restaurantes = [];
  String _busqueda = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargando && _restaurantes.isEmpty) _cargarRestaurantes();
  }

  Future<void> _cargarRestaurantes() async {
    try {
      final token = AuthScope.of(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/admin/listado'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw Exception('No se pudo cargar el listado');
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (mounted) {
        setState(() {
          _restaurantes = data
              .map((item) => RestauranteAdminModel.fromJson(item as Map<String, dynamic>))
              .toList();
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargando = false);
        AdminNotificationModal.error(context, 'No se pudo cargar la gestión de restaurantes.');
      }
    }
  }

  Future<void> _cambiarEstado(RestauranteAdminModel restaurante) async {
    final activar = !restaurante.estado;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activar ? 'Reactivar restaurante' : 'Suspender restaurante'),
        content: Text(activar
            ? '¿Deseas reactivar ${restaurante.nombre}?'
            : '¿Deseas suspender ${restaurante.nombre}? Dejará de mostrarse públicamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(activar ? 'Reactivar' : 'Suspender')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final token = AuthScope.of(context, listen: false).token;
      final response = await http.patch(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/admin/${restaurante.id}/estado'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'estado': activar}),
      );
      if (response.statusCode != 200) throw Exception();
      await _cargarRestaurantes();
      if (mounted) AdminNotificationModal.success(context, activar ? 'Restaurante reactivado.' : 'Restaurante suspendido.');
    } catch (_) {
      if (mounted) AdminNotificationModal.error(context, 'No se pudo actualizar el estado.');
    }
  }

  void _mostrarDetalles(RestauranteAdminModel restaurante) {
    final admin = restaurante.administrador;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restaurante.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detalle('Tipo de comida', restaurante.tipoComida ?? 'No registrado'),
            _detalle('Correo', restaurante.correo ?? 'No registrado'),
            _detalle('Teléfono', restaurante.telefono ?? 'No registrado'),
            _detalle('Solicitud', restaurante.solicitudEstado ?? 'Sin solicitud'),
            _detalle('Administrador', admin == null ? 'No asignado' : '${admin['nombre'] ?? ''} ${admin['apellido'] ?? ''}'.trim()),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Widget _detalle(String label, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RichText(text: TextSpan(style: AdminTheme.bodyStyle, children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
          TextSpan(text: valor),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    final lista = _restaurantes.where((restaurante) {
      final query = _busqueda.toLowerCase();
      return query.isEmpty || restaurante.nombre.toLowerCase().contains(query) || (restaurante.correo ?? '').toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gestión de Restaurantes', style: AdminTheme.titleStyle),
        const SizedBox(height: 8),
        Text('Consulta, revisa y administra las cuentas de restaurantes.', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 24),
        TextField(
          onChanged: (value) => setState(() => _busqueda = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textMuted),
            hintText: 'Buscar por restaurante o correo...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]),
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                : lista.isEmpty
                    ? Center(child: Text('No se encontraron restaurantes', style: AdminTheme.bodyStyle))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final restaurante = lista[index];
                          final color = restaurante.estado ? Colors.green : Colors.redAccent;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: CircleAvatar(backgroundColor: AdminTheme.primaryColor.withOpacity(.1), child: const Icon(Icons.restaurant_rounded, color: AdminTheme.primaryColor)),
                            title: Text(restaurante.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
                            subtitle: Text('${restaurante.tipoComida ?? 'Sin categoría'} · ${restaurante.correo ?? 'Sin correo'}', style: AdminTheme.bodyStyle),
                            trailing: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Chip(label: Text(restaurante.estado ? 'Activo' : 'Suspendido'), labelStyle: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700), backgroundColor: color.withOpacity(.1), side: BorderSide.none),
                              IconButton(tooltip: 'Ver detalles', icon: const Icon(Icons.visibility_outlined), onPressed: () => _mostrarDetalles(restaurante)),
                              IconButton(tooltip: restaurante.estado ? 'Suspender' : 'Reactivar', icon: Icon(restaurante.estado ? Icons.pause_circle_outline : Icons.play_circle_outline, color: restaurante.estado ? Colors.redAccent : Colors.green), onPressed: () => _cambiarEstado(restaurante)),
                            ]),
                          );
                        },
                      ),
          ),
        ),
      ]),
    );
  }
}
