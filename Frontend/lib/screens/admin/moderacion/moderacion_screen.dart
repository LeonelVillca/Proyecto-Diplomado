import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/resena_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class ModeracionScreen extends StatefulWidget {
  const ModeracionScreen({super.key});

  @override
  State<ModeracionScreen> createState() => _ModeracionScreenState();
}

class _ModeracionScreenState extends State<ModeracionScreen> {
  bool _isLoading = true;
  List<ResenaAdminModel> _resenas = [];
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarResenas();
      _isInit = false;
    }
  }

  Future<void> _cargarResenas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final res = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (mounted) setState(() => _resenas = data.map((item) => ResenaAdminModel.fromJson(item)).toList());
      }
    } catch (error) {
      debugPrint('Error cargando reseñas: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarResena(int id) async {
    final confirmar = await AdminModal.show<bool>(
      context: context,
      title: 'Eliminar reseña',
      confirmText: 'Eliminar',
      confirmColor: AdminTheme.error,
      onConfirm: () => Navigator.pop(context, true),
      content: const Text('¿Estás seguro de que deseas eliminar esta reseña permanentemente?'),
    );
    if (confirmar != true) return;

    try {
      final token = AuthScope.of(context).token;
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _resenas.removeWhere((review) => review.id == id));
        AdminNotificationModal.success(context, 'Reseña eliminada correctamente');
      }
    } catch (error) {
      debugPrint('Error eliminando reseña: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              kicker: 'CALIDAD',
              titleBefore: 'Moderación de ',
              titleEmphasis: 'Reseñas',
              description: 'Revisa y elimina comentarios inapropiados de la plataforma.',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AdminSurface(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                    : _resenas.isEmpty
                        ? const _EmptyReviews()
                        : ListView.separated(
                            itemCount: _resenas.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) => _ReviewRow(
                              review: _resenas[index],
                              onDelete: () => _eliminarResena(_resenas[index].id),
                            ),
                          ),
              ),
            ),
          ],
        ),
      );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review, required this.onDelete});

  final ResenaAdminModel review;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final restaurant = review.restaurante?['nombre'] ?? 'Restaurante';
    final user = review.usuario?['nombre'] ?? 'Usuario';
    final date = review.fecha.split('T').first;
    return InkWell(
      hoverColor: AdminTheme.rowHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminInitialAvatar(label: restaurant, size: 42),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(restaurant, style: AdminTheme.subtitleStyle.copyWith(fontSize: 14))),
                      ...List.generate(
                        5,
                        (index) => Icon(index < review.calificacion ? Icons.star_rounded : Icons.star_border_rounded, color: AdminTheme.gold, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(review.comentario ?? '(Sin comentario)', style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark)),
                  const SizedBox(height: 5),
                  Text('Por: $user · $date', style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar reseña',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AdminTheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('No hay reseñas registradas', style: AdminTheme.bodyStyle),
      );
}
