import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;

import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/soporte_admin_model.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

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
      final res = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        setState(() => _tickets = data.map((item) => SoporteAdminModel.fromJson(item)).toList());
      }
    } catch (error) {
      debugPrint('Error cargando tickets de soporte: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _responderTicket(int ticketId, String response) async {
    final auth = AuthScope.of(context, listen: false);
    try {
      final res = await http.patch(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte/$ticketId'),
        headers: {'Authorization': 'Bearer ${auth.token}', 'Content-Type': 'application/json'},
        body: jsonEncode({'respuesta': response}),
      );
      if (res.statusCode == 200 && mounted) {
        AdminNotificationModal.success(context, 'Ticket respondido exitosamente');
        _cargarTickets();
      }
    } catch (error) {
      debugPrint('Error respondiendo ticket: $error');
    }
  }

  void _showRespuestaModal(SoporteAdminModel ticket) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Responder ticket #${ticket.id}', style: AdminTheme.subtitleStyle),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket.asunto, style: AdminTheme.subtitleStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 5),
              Text(ticket.descripcion ?? 'Sin descripción', style: AdminTheme.bodyStyle),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Respuesta al cliente'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              _responderTicket(ticket.id, controller.text.trim());
            },
            child: const Text('Enviar respuesta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              kicker: 'SISTEMA',
              titleBefore: 'Centro de ',
              titleEmphasis: 'Soporte',
              description: 'Revisa y responde los tickets enviados por los usuarios.',
              actions: [
                OutlinedButton.icon(
                  onPressed: _cargarTickets,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AdminSurface(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                    : _tickets.isEmpty
                        ? Center(child: Text('No hay tickets de soporte.', style: AdminTheme.bodyStyle))
                        : ListView.separated(
                            itemCount: _tickets.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) => _SupportTicketRow(
                              ticket: _tickets[index],
                              onReply: () => _showRespuestaModal(_tickets[index]),
                            ),
                          ),
              ),
            ),
          ],
        ),
      );
}

class _SupportTicketRow extends StatelessWidget {
  const _SupportTicketRow({required this.ticket, required this.onReply});

  final SoporteAdminModel ticket;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final user = ticket.usuario != null ? '${ticket.usuario!['nombre']} ${ticket.usuario!['apellido']}' : 'Usuario desconocido';
    final category = ticket.categoriaSoporte?['nombre'] ?? 'General';
    final isAnswered = ticket.respuesta != null;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: AdminInitialAvatar(label: user, round: true, size: 38),
      title: Row(
        children: [
          AdminStatusChip(
            status: isAnswered ? AdminStatus.active : AdminStatus.pending,
            label: ticket.estado.toUpperCase(),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(ticket.asunto, style: AdminTheme.subtitleStyle.copyWith(fontSize: 14))),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text('De: $user · Categoría: $category', style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
      ),
      children: [
        Align(alignment: Alignment.centerLeft, child: Text(ticket.descripcion ?? 'Sin descripción', style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark))),
        const SizedBox(height: 14),
        if (isAnswered)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: AdminTheme.successSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESPUESTA ENVIADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AdminTheme.success)),
                const SizedBox(height: 4),
                Text(ticket.respuesta!, style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark)),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onReply,
              icon: const Icon(Icons.reply_rounded, size: 18),
              label: const Text('Responder ticket'),
            ),
          ),
      ],
    );
  }
}
