import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/soporte_admin_model.dart';
import 'package:frontend/models/admin/categoria_soporte_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class SoporteRestauranteScreen extends StatefulWidget {
  const SoporteRestauranteScreen({super.key});

  @override
  State<SoporteRestauranteScreen> createState() => _SoporteRestauranteScreenState();
}

class _SoporteRestauranteScreenState extends State<SoporteRestauranteScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  List<SoporteAdminModel> _tickets = [];
  List<CategoriaSoporteAdminModel> _categorias = [];

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
      final auth = AuthScope.of(context);
      final token = auth.token;
      final miId = auth.idUsuario ?? 0;

      // 1. Obtener categorias
      final urlCat = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/categoria-soporte');
      final resCat = await http.get(urlCat, headers: {'Authorization': 'Bearer $token'});
      if (resCat.statusCode == 200) {
        final List<dynamic> dataCat = jsonDecode(utf8.decode(resCat.bodyBytes));
        _categorias = dataCat.map((e) => CategoriaSoporteAdminModel.fromJson(e)).toList();
      }

      // 2. Obtener tickets del usuario
      if (miId > 0) {
        final urlTick = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte/usuario/$miId');
        final resTick = await http.get(urlTick, headers: {'Authorization': 'Bearer $token'});
        if (resTick.statusCode == 200) {
          final List<dynamic> dataTick = jsonDecode(utf8.decode(resTick.bodyBytes));
          _tickets = dataTick.map((e) => SoporteAdminModel.fromJson(e)).toList();
          _tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        }
      }
    } catch (e) {
      debugPrint('Error cargando soporte: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirModalCrear() {
    final formKey = GlobalKey<FormState>();
    final asuntoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? selectedCategoriaId = _categorias.isNotEmpty ? _categorias.first.id : null;

    AdminModal.show(
      context: context,
      title: 'Nuevo Ticket de Soporte',
      confirmText: 'Enviar Ticket',
      onConfirm: () async {
        if (formKey.currentState!.validate() && selectedCategoriaId != null) {
          Navigator.pop(context);
          _crearTicket(selectedCategoriaId!, asuntoCtrl.text, descCtrl.text);
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedCategoriaId,
              decoration: AdminInputDecoration.get(labelText: 'Categoría'),
              items: _categorias.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre, style: const TextStyle(fontFamily: 'Karla')))).toList(),
              onChanged: (v) => selectedCategoriaId = v,
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: asuntoCtrl,
              style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
              decoration: AdminInputDecoration.get(labelText: 'Asunto'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un asunto' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Karla', fontSize: 14),
              decoration: AdminInputDecoration.get(labelText: 'Descripción'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una descripción' : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearTicket(int idCategoria, String asunto, String descripcion) async {
    setState(() => _isLoading = true);
    try {
      final auth = AuthScope.of(context);
      final token = auth.token;
      final miId = auth.idUsuario ?? 0;
      
      await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': miId,
          'idCategoriaSoporte': idCategoria,
          'asunto': asunto.trim(),
          'descripcion': descripcion.trim(),
        }),
      );
      await _cargarDatos();
      if (mounted) AdminNotificationModal.success(context, 'Ticket enviado correctamente');
    } catch (e) {
      debugPrint('Error creando ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          kicker: 'AYUDA',
          titleBefore: 'Centro de ',
          titleEmphasis: 'Soporte',
          description: 'Consulta tus tickets y comunícate con el equipo de soporte.',
          actions: [
            FilledButton.icon(onPressed: _abrirModalCrear, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nuevo ticket')),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: AdminSurface(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? Center(child: Text('No tienes tickets de soporte.', style: AdminTheme.bodyStyle))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        final fecha = DateTime.tryParse(t.fechaCreacion);
                        final strFecha = fecha != null ? '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}' : '';
                        final esRespondido = t.estado == 'respondida';
                        return Container(
                          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: AdminTheme.mediumRadius, border: Border.all(color: AdminTheme.border)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t.asunto, style: AdminTheme.subtitleStyle.copyWith(fontSize: 16)),
                                    AdminStatusChip(status: esRespondido ? AdminStatus.active : AdminStatus.pending, label: t.estado.toUpperCase()),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(t.descripcion ?? '', style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark)),
                                const SizedBox(height: 8),
                                Text('Categoría: ${t.categoriaSoporte?['nombre'] ?? '-'} · Fecha: $strFecha', style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
                                if (esRespondido && t.respuesta != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AdminTheme.successSoft, borderRadius: BorderRadius.circular(14)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('RESPUESTA DEL ADMINISTRADOR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1, color: AdminTheme.success)),
                                        const SizedBox(height: 4),
                                        Text(t.respuesta!, style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark)),
                                      ],
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
        ),
      ],
      ),
    );
  }
}
