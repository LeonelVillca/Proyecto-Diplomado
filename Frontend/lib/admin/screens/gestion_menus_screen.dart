import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/menu_admin_model.dart';
import '../models/plato_admin_model.dart';

class GestionMenusScreen extends StatefulWidget {
  const GestionMenusScreen({super.key});

  @override
  State<GestionMenusScreen> createState() => _GestionMenusScreenState();
}

class _GestionMenusScreenState extends State<GestionMenusScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  int? _idRestaurante;
  List<MenuAdminModel> _menus = [];
  Map<int, int> _cantidadPlatillos = {}; // menuId -> count

  // Estado para alternar entre listado y formulario de creación
  bool _mostrandoFormulario = false;

  // Controladores Formulario
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreMenuCtrl;
  String _tipoMenu = 'Diario';
  List<Map<String, dynamic>> _platillosForm = []; // [{'nombre': Ctrl, 'precio': Ctrl, 'desc': Ctrl}]

  @override
  void initState() {
    super.initState();
    _nombreMenuCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nombreMenuCtrl.dispose();
    _limpiarPlatillosForm();
    super.dispose();
  }

  void _limpiarPlatillosForm() {
    for (var p in _platillosForm) {
      p['nombre'].dispose();
      p['precio'].dispose();
      p['desc'].dispose();
    }
    _platillosForm.clear();
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
          
          // 2. Obtener menús
          final urlMenus = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/restaurante/$_idRestaurante');
          final resMenus = await http.get(urlMenus, headers: {'Authorization': 'Bearer $token'});

          if (resMenus.statusCode == 200) {
            final List<dynamic> dataMenus = jsonDecode(utf8.decode(resMenus.bodyBytes));
            _menus = dataMenus.map((e) => MenuAdminModel.fromJson(e)).toList();

            // 3. Obtener cantidad de platillos por menú
            _cantidadPlatillos.clear();
            for (var m in _menus) {
              final resPlatos = await http.get(
                Uri.parse('${ApiEndpoints.baseUrl}/api/v1/plato/menu/${m.id}'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (resPlatos.statusCode == 200) {
                final List<dynamic> platos = jsonDecode(utf8.decode(resPlatos.bodyBytes));
                _cantidadPlatillos[m.id] = platos.length;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando menús: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _agregarPlatilloVacio() {
    setState(() {
      _platillosForm.add({
        'nombre': TextEditingController(),
        'precio': TextEditingController(),
        'desc': TextEditingController(),
      });
    });
  }

  void _abrirCrearMenu() {
    _nombreMenuCtrl.clear();
    _tipoMenu = 'Diario';
    _limpiarPlatillosForm();
    _agregarPlatilloVacio(); // Empieza con 1
    setState(() => _mostrandoFormulario = true);
  }

  Future<void> _guardarMenuCompleto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idRestaurante == null) return;

    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      
      // 1. Crear Menú
      final resMenu = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'idRestaurante': _idRestaurante,
          'nombre': _nombreMenuCtrl.text.trim(),
          'tipo': _tipoMenu,
          'disponibilidad': true,
        }),
      );

      if (resMenu.statusCode == 201) {
        final menuData = jsonDecode(utf8.decode(resMenu.bodyBytes));
        final menuId = menuData['id'];

        // 2. Crear cada platillo
        for (var p in _platillosForm) {
          await http.post(
            Uri.parse('${ApiEndpoints.baseUrl}/api/v1/plato'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode({
              'idMenu': menuId,
              'nombre': p['nombre'].text.trim(),
              'descripcion': p['desc'].text.trim(),
              'precio': double.tryParse(p['precio'].text.trim()) ?? 0,
              'disponibilidad': true,
            }),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menú guardado con éxito')));
          setState(() => _mostrandoFormulario = false);
        }
        await _cargarDatos();
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMenu(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Menú', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Seguro que deseas eliminar este menú y todos sus platillos?'),
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
      final res = await http.delete(Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/$id'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        setState(() => _menus.removeWhere((m) => m.id == id));
      }
    } catch (e) {
      debugPrint('Error eliminando menú: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDisponibilidad(MenuAdminModel menu) async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final res = await http.patch(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/menu/${menu.id}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'disponibilidad': !menu.disponibilidad}),
      );
      if (res.statusCode == 200) {
        await _cargarDatos();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _menus.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mostrandoFormulario) {
      return _buildFormulario();
    }

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
                  'Gestión de Menús',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea y organiza los platillos que ofreces a tus clientes.',
                  style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _abrirCrearMenu,
              icon: const Icon(Icons.add),
              label: const Text('Crear Menú'),
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
          child: _menus.isEmpty
              ? Center(child: Text('No hay menús registrados.', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.separated(
                  itemCount: _menus.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final menu = _menus[index];
                    final cant = _cantidadPlatillos[menu.id] ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B1A35).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.menu_book, color: Color(0xFF6B1A35)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Karla')),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tipo: ${menu.tipo ?? 'N/A'} • $cant platillos',
                                    style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: menu.disponibilidad ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                menu.disponibilidad ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: menu.disponibilidad ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Switch(
                              value: menu.disponibilidad,
                              onChanged: (v) => _toggleDisponibilidad(menu),
                              activeColor: const Color(0xFF6B1A35),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _eliminarMenu(menu.id),
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

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _mostrandoFormulario = false),
            ),
            const SizedBox(width: 8),
            const Text(
              'Crear Nuevo Menú',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarMenuCompleto,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B1A35), foregroundColor: Colors.white),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar Menú'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información del Menú', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nombreMenuCtrl,
                            decoration: const InputDecoration(labelText: 'Nombre del Menú', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _tipoMenu,
                            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                            items: ['Diario', 'Fin de semana', 'Especial'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => _tipoMenu = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platillos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        OutlinedButton.icon(
                          onPressed: _agregarPlatilloVacio,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Platillo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ..._platillosForm.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Platillo #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (_platillosForm.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        p['nombre'].dispose();
                                        p['precio'].dispose();
                                        p['desc'].dispose();
                                        _platillosForm.removeAt(idx);
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: p['nombre'],
                                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: p['precio'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Precio (Bs)', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: p['desc'],
                              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
