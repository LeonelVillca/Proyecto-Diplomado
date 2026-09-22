import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/restaurante_admin_model.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';
import 'package:frontend/widgets/admin/admin_restaurant_detail_modal.dart';

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
      if (!mounted) return;
      setState(() {
        _restaurantes = data
            .map((item) => RestauranteAdminModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      AdminNotificationModal.error(context, 'No se pudo cargar la gestión de restaurantes.');
    }
  }

  Future<void> _cambiarEstado(RestauranteAdminModel restaurante) async {
    final activar = !restaurante.estado;
    final confirmar = await AdminModal.show<bool>(
      context: context,
      title: activar ? 'Reactivar restaurante' : 'Suspender restaurante',
      width: 420,
      confirmText: activar ? 'Reactivar' : 'Suspender',
      confirmColor: activar ? AdminTheme.success : AdminTheme.warning,
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (activar ? AdminTheme.successSoft : AdminTheme.warningSoft),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              activar ? Icons.play_arrow_rounded : Icons.warning_amber_rounded,
              color: activar ? AdminTheme.success : AdminTheme.warning,
              size: 27,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            activar
                ? '¿Deseas reactivar ${restaurante.nombre}?'
                : '¿Deseas suspender ${restaurante.nombre}?',
            style: AdminTheme.subtitleStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.background,
              border: Border.all(color: AdminTheme.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: activar ? AdminTheme.success : AdminTheme.warning),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    activar
                        ? 'El restaurante volverá a estar disponible públicamente.'
                        : 'El restaurante dejará de mostrarse públicamente hasta que lo reactives.',
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
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
      if (mounted) {
        AdminNotificationModal.success(
          context,
          activar ? 'Restaurante reactivado.' : 'Restaurante suspendido.',
        );
      }
    } catch (_) {
      if (mounted) AdminNotificationModal.error(context, 'No se pudo actualizar el estado.');
    }
  }

  void _mostrarDetalles(RestauranteAdminModel restaurante) {
    AdminRestaurantDetailModal.show(context, restaurante);
  }


  @override
  Widget build(BuildContext context) {
    final lista = _restaurantes.where((restaurante) {
      final query = _busqueda.toLowerCase();
      return query.isEmpty ||
          restaurante.nombre.toLowerCase().contains(query) ||
          (restaurante.correo ?? '').toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            kicker: 'CATÁLOGO',
            titleBefore: 'Gestión de ',
            titleEmphasis: 'Restaurantes',
            description: 'Consulta, revisa y administra las cuentas de restaurantes.',
          ),
          const SizedBox(height: 24),
          AdminSurface(
            padding: const EdgeInsets.all(14),
            radius: AdminTheme.mediumRadius,
            child: AdminSearchField(
              onChanged: (value) => setState(() => _busqueda = value),
              hintText: 'Buscar por restaurante o correo...',
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AdminSurface(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                  : lista.isEmpty
                      ? const _RestaurantsEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: constraints.maxWidth < 860 ? 860 : constraints.maxWidth,
                              child: Column(
                                children: [
                                  const _RestaurantTableHeader(),
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: lista.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) => _RestaurantTableRow(
                                        restaurant: lista[index],
                                        onDetails: () => _mostrarDetalles(lista[index]),
                                        onChangeStatus: () => _cambiarEstado(lista[index]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantTableHeader extends StatelessWidget {
  const _RestaurantTableHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: AdminTheme.surfaceMuted,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: const Row(
          children: [
            Expanded(flex: 3, child: _TableLabel('RESTAURANTE')),
            Expanded(flex: 3, child: _TableLabel('CORREO')),
            Expanded(flex: 2, child: _TableLabel('CATEGORÍA')),
            Expanded(flex: 2, child: _TableLabel('ESTADO')),
            SizedBox(width: 112, child: _TableLabel('ACCIÓN', textAlign: TextAlign.right)),
          ],
        ),
      );
}

class _RestaurantTableRow extends StatelessWidget {
  const _RestaurantTableRow({
    required this.restaurant,
    required this.onDetails,
    required this.onChangeStatus,
  });

  final RestauranteAdminModel restaurant;
  final VoidCallback onDetails;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onDetails,
        hoverColor: AdminTheme.rowHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    AdminInitialAvatar(label: restaurant.nombre),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.subtitleStyle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Cuenta de restaurante', style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 15, color: AdminTheme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(restaurant.correo ?? 'Sin correo', maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 13))),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(restaurant.tipoComida ?? 'Sin categoría', maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600))),
              Expanded(
                flex: 2,
                child: AdminStatusChip(
                  status: restaurant.estado ? AdminStatus.active : AdminStatus.suspended,
                  label: restaurant.estado ? 'Activo' : 'Suspendido',
                ),
              ),
              SizedBox(
                width: 112,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Ver detalles',
                      onPressed: onDetails,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      color: AdminTheme.textMuted,
                    ),
                    IconButton(
                      tooltip: restaurant.estado ? 'Suspender' : 'Reactivar',
                      onPressed: onChangeStatus,
                      icon: Icon(restaurant.estado ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 19),
                      color: restaurant.estado ? AdminTheme.error : AdminTheme.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _TableLabel extends StatelessWidget {
  const _TableLabel(this.label, {this.textAlign = TextAlign.left});

  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: textAlign,
        style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
      );
}

class _RestaurantsEmptyState extends StatelessWidget {
  const _RestaurantsEmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AdminTheme.background, border: Border.all(color: AdminTheme.border), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.search_off_rounded, color: AdminTheme.textLight, size: 28),
            ),
            const SizedBox(height: 14),
            Text('Sin resultados', style: AdminTheme.titleStyle.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text('No se encontraron restaurantes con esa búsqueda.', style: AdminTheme.bodyStyle),
          ],
        ),
      );
}
