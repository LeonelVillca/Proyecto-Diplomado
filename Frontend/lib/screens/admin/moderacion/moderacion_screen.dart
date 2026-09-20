import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/resena_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

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
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _resenas = data.map((e) => ResenaAdminModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando reseñas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarResena(int id) async {
    final confirmar = await AdminModal.show<bool>(
      context: context,
      title: 'Eliminar Reseña',
      confirmText: 'Eliminar',
      confirmColor: Colors.redAccent,
      onConfirm: () => Navigator.pop(context, true),
      content: const Text('¿Estás seguro de que deseas eliminar esta reseña permanentemente?', style: TextStyle(fontFamily: 'Karla')),
    );

    if (confirmar != true) return;

    try {
      final token = AuthScope.of(context).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/$id');
      final res = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        setState(() {
          _resenas.removeWhere((r) => r.id == id);
        });
        if (mounted) {
          AdminNotificationModal.success(context, 'Reseña eliminada correctamente');
        }
      }
    } catch (e) {
      debugPrint('Error eliminando reseña: $e');
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moderación de Reseñas',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Revisa y elimina comentarios inapropiados de la plataforma.',
          style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _resenas.isEmpty
                  ? Center(child: Text('No hay reseñas registradas', style: TextStyle(fontFamily: 'Karla', color: Colors.grey.shade500)))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: _resenas.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final resena = _resenas[index];
                          final nombreRestaurante = resena.restaurante?['nombre'] ?? 'Restaurante';
                          final nombreUsuario = resena.usuario?['nombre'] ?? 'Usuario';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            title: Row(
                              children: [
                                _buildStars(resena.calificacion),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nombreRestaurante,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Karla', fontSize: 15, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resena.comentario ?? '(Sin comentario)',
                                    style: TextStyle(color: Colors.grey.shade800, fontFamily: 'Karla', fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Por: $nombreUsuario • ${resena.fecha.split('T')[0]}',
                                    style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Karla', fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Eliminar reseña',
                              onPressed: () => _eliminarResena(resena.id),
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
