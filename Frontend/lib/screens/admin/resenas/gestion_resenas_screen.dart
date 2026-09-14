import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/resena_admin_model.dart';
import 'package:frontend/models/admin/respuesta_resena_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

class GestionResenasScreen extends StatefulWidget {
  const GestionResenasScreen({super.key});

  @override
  State<GestionResenasScreen> createState() => _GestionResenasScreenState();
}

class _GestionResenasScreenState extends State<GestionResenasScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  int? _idRestaurante;
  List<ResenaAdminModel> _resenas = [];
  Map<int, RespuestaResenaAdminModel?> _respuestas = {}; // resenaId -> respuesta

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context).token;

      // 1. Obtener restaurante
      final urlRest = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final resRest = await http.get(urlRest, headers: {'Authorization': 'Bearer $token'});

      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(utf8.decode(resRest.bodyBytes));
        if (dataRest.isNotEmpty) {
          _idRestaurante = dataRest.first['id'];
          
          // 2. Obtener reseñas del restaurante
          final urlResenas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/restaurante/$_idRestaurante');
          final resResenas = await http.get(urlResenas, headers: {'Authorization': 'Bearer $token'});

          if (resResenas.statusCode == 200) {
            final List<dynamic> dataResenas = jsonDecode(utf8.decode(resResenas.bodyBytes));
            _resenas = dataResenas.map((e) => ResenaAdminModel.fromJson(e)).toList();
            // Ordenar por fecha descendente
            _resenas.sort((a, b) => b.fecha.compareTo(a.fecha));

            // 3. Obtener respuestas
            _respuestas.clear();
            for (var r in _resenas) {
              final urlResp = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/respuesta-resena/resena/${r.id}');
              final resResp = await http.get(urlResp, headers: {'Authorization': 'Bearer $token'});
              if (resResp.statusCode == 200) {
                final List<dynamic> dataResp = jsonDecode(utf8.decode(resResp.bodyBytes));
                if (dataResp.isNotEmpty) {
                  _respuestas[r.id] = RespuestaResenaAdminModel.fromJson(dataResp.first);
                } else {
                  _respuestas[r.id] = null;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando reseñas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirModalRespuesta(ResenaAdminModel resena, {RespuestaResenaAdminModel? respuestaExistente}) {
    final formKey = GlobalKey<FormState>();
    final textoCtrl = TextEditingController(text: respuestaExistente?.texto ?? '');

    AdminModal.show(
      context: context,
      title: respuestaExistente == null ? 'Responder Reseña' : 'Editar Respuesta',
      confirmText: 'Publicar Respuesta',
      onConfirm: () async {
        if (formKey.currentState!.validate()) {
          Navigator.pop(context);
          _guardarRespuesta(resena.id, textoCtrl.text, respuestaId: respuestaExistente?.id);
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EE).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8DCC4).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF6E1F35).withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 14, color: Color(0xFF6E1F35)),
                      ),
                      const SizedBox(width: 8),
                      Text(resena.usuario?['nombre'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla', color: Color(0xFF1A0A00))),
                      const Spacer(),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < resena.calificacion ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFD4AF37),
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('"${resena.comentario ?? '(Sin comentario)'}"', style: const TextStyle(fontFamily: 'Karla', fontStyle: FontStyle.italic, color: Color(0xFF6B5A4A))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: textoCtrl,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Karla'),
              decoration: AdminInputDecoration.get(
                labelText: 'Tu respuesta pública',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Escribe una respuesta' : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarRespuesta(int idResena, String texto, {int? respuestaId}) async {
    setState(() => _isLoading = true);
    try {
      final auth = AuthScope.of(context);
      final token = auth.token;
      // Asumiendo que el ID del usuario actual está en el token, se necesita enviarlo
      // El backend requiere idUsuarioRestaurante en el DTO
      final miId = auth.idUsuario ?? 0;

      if (respuestaId == null) {
        // Crear
        await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/respuesta-resena'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'idResena': idResena,
            'idUsuarioRestaurante': miId,
            'texto': texto.trim(),
          }),
        );
      } else {
        // Actualizar
        await http.patch(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/respuesta-resena/$respuestaId'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'texto': texto.trim(),
          }),
        );
      }
      await _cargarDatos();
      if (mounted) AdminNotificationModal.success(context, 'Respuesta publicada con éxito');
    } catch (e) {
      debugPrint('Error guardando respuesta: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión de Reseñas',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Color(0xFF1A0A00)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Revisa el feedback de tus clientes y dales una respuesta profesional.',
          style: TextStyle(color: Color(0xFF6B5A4A), fontFamily: 'Karla', fontSize: 16),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1F35)))
              : _resenas.isEmpty
                  ? const Center(child: Text('No has recibido reseñas todavía.', style: TextStyle(color: Color(0xFF6B5A4A), fontFamily: 'Karla', fontSize: 16)))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 32, right: 16),
                      itemCount: _resenas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final resena = _resenas[index];
                        final respuesta = _respuestas[resena.id];
                        final fecha = DateTime.tryParse(resena.fecha);
                        final strFecha = fecha != null ? '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}' : '';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF0EBE1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFFF9F5EE),
                                      child: Text(
                                        (resena.usuario?['nombre'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(resena.usuario?['nombre'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Karla', color: Color(0xFF1A0A00))),
                                              Text(strFecha, style: const TextStyle(color: Color(0xFF9E9284), fontSize: 13, fontFamily: 'Karla')),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: List.generate(5, (starIndex) {
                                              return Icon(
                                                starIndex < resena.calificacion ? Icons.star_rounded : Icons.star_border_rounded,
                                                color: const Color(0xFFD4AF37),
                                                size: 20,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  resena.comentario ?? '(Sin comentario)', 
                                  style: const TextStyle(fontSize: 16, fontFamily: 'Karla', color: Color(0xFF4A3F35), height: 1.5)
                                ),
                                const SizedBox(height: 24),

                                if (respuesta != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F5EE),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE8DCC4).withValues(alpha: 0.5)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.subdirectory_arrow_right_rounded, size: 20, color: Color(0xFFD4AF37)),
                                            const SizedBox(width: 8),
                                            const Text('Tu respuesta', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A0A00), fontFamily: 'Karla', fontSize: 15)),
                                            const Spacer(),
                                            TextButton.icon(
                                              onPressed: () => _abrirModalRespuesta(resena, respuestaExistente: respuesta),
                                              icon: const Icon(Icons.edit_outlined, size: 16),
                                              label: const Text('Editar'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFF6E1F35),
                                                textStyle: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          respuesta.texto, 
                                          style: const TextStyle(color: Color(0xFF6B5A4A), fontFamily: 'Karla', fontSize: 15, height: 1.5)
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _abrirModalRespuesta(resena),
                                      icon: const Icon(Icons.reply_rounded, size: 18),
                                      label: const Text('Responder'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF6E1F35),
                                        elevation: 0,
                                        side: const BorderSide(color: Color(0xFF6E1F35)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        textStyle: const TextStyle(fontFamily: 'Karla', fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
