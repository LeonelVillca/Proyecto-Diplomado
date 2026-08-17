import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_endpoints.dart';
import '../../../movil/providers/auth_provider.dart';
import '../../models/soporte_admin_model.dart';
import '../../models/categoria_soporte_admin_model.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Ticket de Soporte', style: TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategoriaId,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: _categorias.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) => selectedCategoriaId = v,
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: asuntoCtrl,
                decoration: const InputDecoration(labelText: 'Asunto', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un asunto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una descripción' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedCategoriaId != null) {
                Navigator.pop(ctx);
                _crearTicket(selectedCategoriaId!, asuntoCtrl.text, descCtrl.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white),
            child: const Text('Enviar Ticket'),
          ),
        ],
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket enviado')));
    } catch (e) {
      debugPrint('Error creando ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Soporte y Ayuda', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87)),
                const SizedBox(height: 8),
                Text('Gestiona tus tickets de soporte y contáctanos.', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _abrirModalCrear,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Ticket'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? Center(child: Text('No tienes tickets de soporte.', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.separated(
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        final fecha = DateTime.tryParse(t.fechaCreacion);
                        final strFecha = fecha != null ? '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}' : '';
                        final esRespondido = t.estado == 'respondida';
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t.asunto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Karla')),
                                    Chip(
                                      label: Text(t.estado.toUpperCase(), style: TextStyle(color: esRespondido ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                      backgroundColor: esRespondido ? Colors.green.shade50 : Colors.orange.shade50,
                                      side: BorderSide.none,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(t.descripcion ?? '', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Text('Categoría: ${t.categoriaSoporte?['nombre'] ?? '-'} | Fecha: $strFecha', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                if (esRespondido && t.respuesta != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Respuesta del Administrador:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                                        const SizedBox(height: 4),
                                        Text(t.respuesta!, style: const TextStyle(fontSize: 14)),
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
      ],
    );
  }
}
