import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/resena_admin_model.dart';
import 'package:frontend/models/admin/respuesta_resena_admin_model.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(respuestaExistente == null ? 'Responder Reseña' : 'Editar Respuesta', style: const TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reseña de ${resena.usuario?['nombre'] ?? 'Usuario'}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(resena.comentario ?? '(Sin comentario)', style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: textoCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta',
                  border: OutlineInputBorder(),
                  hintText: 'Agradece o responde educadamente al cliente...',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Escribe una respuesta' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                _guardarRespuesta(resena.id, textoCtrl.text, respuestaId: respuestaExistente?.id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white),
            child: const Text('Publicar Respuesta'),
          ),
        ],
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Respuesta publicada con éxito')));
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
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Revisa el feedback de tus clientes y dales una respuesta profesional.',
          style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _resenas.isEmpty
                  ? Center(child: Text('No has recibido reseñas todavía.', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.separated(
                      itemCount: _resenas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final resena = _resenas[index];
                        final respuesta = _respuestas[resena.id];
                        final fecha = DateTime.tryParse(resena.fecha);
                        final strFecha = fecha != null ? '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}' : '';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF6B1A35).withValues(alpha: 0.1),
                                      child: const Icon(Icons.person, color: Color(0xFF6B1A35)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(resena.usuario?['nombre'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Karla')),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: List.generate(5, (starIndex) {
                                              return Icon(
                                                starIndex < resena.calificacion ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(strFecha, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(resena.comentario ?? '(Sin comentario)', style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 16),

                                if (respuesta != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.reply, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            const Text('Tu respuesta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => _abrirModalRespuesta(resena, respuestaExistente: respuesta),
                                              child: const Text('Editar'),
                                            ),
                                          ],
                                        ),
                                        Text(respuesta.texto, style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _abrirModalRespuesta(resena),
                                      icon: const Icon(Icons.reply),
                                      label: const Text('Responder'),
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
