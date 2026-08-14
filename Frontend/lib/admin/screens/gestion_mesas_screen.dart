import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/mesa_admin_model.dart';

class GestionMesasScreen extends StatefulWidget {
  const GestionMesasScreen({super.key});

  @override
  State<GestionMesasScreen> createState() => _GestionMesasScreenState();
}

class _GestionMesasScreenState extends State<GestionMesasScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  int? _idRestaurante;
  List<MesaAdminModel> _mesas = [];

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
          
          // 2. Obtener mesas
          final urlMesas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/restaurante/$_idRestaurante');
          final resMesas = await http.get(urlMesas, headers: {'Authorization': 'Bearer $token'});

          if (resMesas.statusCode == 200) {
            final List<dynamic> dataMesas = jsonDecode(utf8.decode(resMesas.bodyBytes));
            _mesas = dataMesas.map((e) => MesaAdminModel.fromJson(e)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirModalMesa({MesaAdminModel? mesa}) {
    if (_idRestaurante == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes un restaurante asociado.')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroCtrl = TextEditingController(text: mesa?.numeroMesa ?? '');
    final capacidadCtrl = TextEditingController(text: mesa?.capacidad.toString() ?? '2');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mesa == null ? 'Nueva Mesa' : 'Editar Mesa', style: const TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numeroCtrl,
                decoration: const InputDecoration(labelText: 'Identificador (Ej: Mesa 1)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: capacidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacidad (personas)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
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
                final body = {
                  'idRestaurante': _idRestaurante,
                  'numeroMesa': numeroCtrl.text,
                  'capacidad': int.parse(capacidadCtrl.text),
                  'estado': mesa?.estado ?? 'libre',
                };
                Navigator.pop(ctx);
                _guardarMesa(body, mesa?.id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarMesa(Map<String, dynamic> body, int? idMesa) async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final url = idMesa == null 
          ? Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa')
          : Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$idMesa');
      
      final req = idMesa == null 
          ? http.post(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(body))
          : http.patch(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(body));
          
      final res = await req;
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _cargarDatos();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesa guardada exitosamente')));
      } else {
        debugPrint('Error guardando mesa: ${res.body}');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar mesa')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMesa(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mesa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Seguro que deseas eliminar esta mesa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );

    if (conf != true) return;
    setState(() => _isLoading = true);
    
    try {
      final token = AuthScope.of(context).token;
      final res = await http.delete(Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$id'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        setState(() => _mesas.removeWhere((m) => m.id == id));
      }
    } catch (e) {
      debugPrint('Error eliminando mesa: $e');
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
                const Text(
                  'Gestión de Mesas',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra la capacidad y distribución de tu restaurante.',
                  style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _abrirModalMesa(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Mesa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B1A35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mesas.isEmpty
                  ? Center(child: Text('No hay mesas registradas.', style: TextStyle(color: Colors.grey.shade500)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _mesas.length,
                      itemBuilder: (context, index) {
                        final mesa = _mesas[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        mesa.numeroMesa,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla', fontSize: 16),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'edit') _abrirModalMesa(mesa: mesa);
                                        if (val == 'delete') _eliminarMesa(mesa.id);
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                        const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('${mesa.capacidad} personas', style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Karla')),
                                  ],
                                ),
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
