import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/soporte_admin_model.dart';
import 'package:frontend/core/movil/theme.dart'; // Usaremos algunos colores del theme principal
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

class AdminSoporteScreen extends StatefulWidget {
  const AdminSoporteScreen({super.key});

  @override
  State<AdminSoporteScreen> createState() => _AdminSoporteScreenState();
}

class _AdminSoporteScreenState extends State<AdminSoporteScreen> {
  bool _isLoading = true;
  List<SoporteAdminModel> _tickets = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarTickets());
  }

  Future<void> _cargarTickets() async {
    final auth = AuthScope.of(context, listen: false);
    
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte');
      final res = await http.get(url, headers: {'Authorization': 'Bearer ${auth.token}'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _tickets = data.map((e) => SoporteAdminModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando tickets de soporte: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _responderTicket(int idTicket, String respuestaText) async {
    final auth = AuthScope.of(context, listen: false);
    
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte/$idTicket');
      final res = await http.patch(
        url, 
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'respuesta': respuestaText}),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          AdminNotificationModal.success(context, 'Ticket respondido exitosamente');
          _cargarTickets();
        }
      }
    } catch (e) {
      debugPrint('Error respondiendo ticket: $e');
    }
  }

  void _showRespuestaModal(SoporteAdminModel ticket) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Responder Ticket #${ticket.id}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asunto:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                Text(ticket.asunto, style: GoogleFonts.manrope(fontSize: 14)),
                const SizedBox(height: 12),
                Text('Descripción:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                Text(ticket.descripcion ?? 'Sin descripción', style: GoogleFonts.manrope(fontSize: 14)),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Respuesta al cliente',
                    border: OutlineInputBorder(),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _responderTicket(ticket.id, ctrl.text.trim());
                }
              },
              child: const Text('Enviar Respuesta'),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Centro de Soporte', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTickets),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _tickets.isEmpty
                ? const Center(child: Text('No hay tickets de soporte.'))
                : ListView.builder(
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final estadoColor = ticket.estado == 'pendiente' ? Colors.orange : Colors.green;
                      final userName = ticket.usuario != null ? '${ticket.usuario!['nombre']} ${ticket.usuario!['apellido']}' : 'Usuario Desconocido';
                      final catName = ticket.categoriaSoporte != null ? ticket.categoriaSoporte!['nombre'] : 'General';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(ticket.estado.toUpperCase(), style: GoogleFonts.manrope(color: estadoColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(ticket.asunto, style: GoogleFonts.manrope(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('De: $userName • Categoría: $catName', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[700])),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Descripción del Problema:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                  const SizedBox(height: 8),
                                  Text(ticket.descripcion ?? 'Sin descripción', style: GoogleFonts.manrope(fontSize: 14)),
                                  const SizedBox(height: 16),
                                  
                                  if (ticket.respuesta != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.2))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tu Respuesta:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.green[800])),
                                          const SizedBox(height: 4),
                                          Text(ticket.respuesta!, style: GoogleFonts.manrope(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: () => _showRespuestaModal(ticket),
                                        icon: const Icon(Icons.reply, size: 18),
                                        label: const Text('Responder Ticket'),
                                        style: FilledButton.styleFrom(backgroundColor: AppColors.wine),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
