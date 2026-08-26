import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/mesa_admin_model.dart';

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
  String _filtroEstado = 'todas';

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
      final urlRest = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final resRest = await http.get(urlRest, headers: {'Authorization': 'Bearer $token'});
      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(utf8.decode(resRest.bodyBytes));
        if (dataRest.isNotEmpty) {
          _idRestaurante = dataRest.first['id'];
          final urlMesas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/restaurante/$_idRestaurante');
          final resMesas = await http.get(urlMesas, headers: {'Authorization': 'Bearer $token'});
          if (resMesas.statusCode == 200) {
            final List<dynamic> dataMesas = jsonDecode(utf8.decode(resMesas.bodyBytes));
            _mesas = dataMesas.map((e) => MesaAdminModel.fromJson(e)).toList();
            _mesas.sort((a, b) => a.id.compareTo(b.id)); // o por numeroMesa
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstadoMesa(MesaAdminModel mesa) async {
    String nuevoEstado = 'libre';
    if (mesa.estado == 'libre') nuevoEstado = 'ocupada';
    else if (mesa.estado == 'ocupada') nuevoEstado = 'reservada';
    else if (mesa.estado == 'reservada') nuevoEstado = 'libre';
    else if (mesa.estado == 'inactiva') return;

    // Optimistic UI Update
    final originalMesas = List<MesaAdminModel>.from(_mesas);
    setState(() {
      final idx = _mesas.indexWhere((m) => m.id == mesa.id);
      if (idx != -1) {
        _mesas[idx] = MesaAdminModel(
          id: mesa.id,
          numeroMesa: mesa.numeroMesa,
          capacidad: mesa.capacidad,
          estado: nuevoEstado,
        );
      }
    });

    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/${mesa.id}');
      final res = await http.patch(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Error al actualizar estado');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _mesas = originalMesas);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar el estado')));
    }
  }

  void _abrirModalMesa({MesaAdminModel? mesa}) {
    if (_idRestaurante == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes un restaurante asociado.')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroCtrl = TextEditingController(text: mesa?.numeroMesa ?? '');
    final capacidadCtrl = TextEditingController(text: mesa?.capacidad.toString() ?? '4');
    String estadoSeleccionado = mesa?.estado ?? 'libre';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFCF4F7), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.table_restaurant, color: Color(0xFF6E1E39)),
            ),
            const SizedBox(width: 12),
            Text(mesa == null ? 'Nueva Mesa' : 'Editar Mesa', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14), fontSize: 22)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numeroCtrl,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Identificador (Ej: Mesa 1, Barra 2)',
                  labelStyle: GoogleFonts.manrope(color: const Color(0xFF6B635E)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: capacidadCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Capacidad de Personas',
                  labelStyle: GoogleFonts.manrope(color: const Color(0xFF6B635E)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                validator: (v) => v == null || v.trim().isEmpty || int.tryParse(v) == null ? 'Número válido requerido' : null,
              ),
              if (mesa != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: estadoSeleccionado,
                  style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Estado Inicial',
                    labelStyle: GoogleFonts.manrope(color: const Color(0xFF6B635E)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'libre', child: Text('Libre')),
                    DropdownMenuItem(value: 'ocupada', child: Text('Ocupada')),
                    DropdownMenuItem(value: 'reservada', child: Text('Reservada')),
                    DropdownMenuItem(value: 'inactiva', child: Text('Inactiva')),
                  ],
                  onChanged: (v) => estadoSeleccionado = v!,
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF6B635E))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final body = {
                  'idRestaurante': _idRestaurante,
                  'numeroMesa': numeroCtrl.text.trim(),
                  'capacidad': int.parse(capacidadCtrl.text.trim()),
                  'estado': estadoSeleccionado,
                };
                Navigator.pop(ctx);
                _guardarMesa(body, mesa?.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E1E39),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(mesa == null ? 'Crear Mesa' : 'Guardar Cambios', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarMesa(Map<String, dynamic> body, int? idMesa) async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = idMesa == null 
          ? Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa')
          : Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$idMesa');
      
      final req = idMesa == null 
          ? http.post(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(body))
          : http.patch(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(body));
          
      final res = await req;
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('✅ Mesa guardada exitosamente'),
            backgroundColor: const Color(0xFF6E1E39),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar mesa')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMesa(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar Mesa', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFFE74C3C))),
        content: Text('¿Seguro que deseas eliminar esta mesa permanentemente?', style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Eliminar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (conf != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final res = await http.delete(Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$id'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        if (mounted) setState(() => _mesas.removeWhere((m) => m.id == id));
      }
    } catch (e) {
      debugPrint('Error eliminando mesa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'libre': return const Color(0xFF2ECC71);
      case 'ocupada': return const Color(0xFF3498DB);
      case 'reservada': return const Color(0xFFF39C12);
      case 'inactiva': return const Color(0xFF95A5A6);
      default: return const Color(0xFF95A5A6);
    }
  }
  
  IconData _getIconEstado(String estado) {
    switch (estado) {
      case 'libre': return Icons.check_circle_rounded;
      case 'ocupada': return Icons.remove_circle_rounded;
      case 'reservada': return Icons.schedule_rounded;
      default: return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesasFiltradas = _filtroEstado == 'todas' ? _mesas : _mesas.where((m) => m.estado == _filtroEstado).toList();

    int capacidadTotal = _mesas.fold(0, (sum, m) => sum + m.capacidad);
    int libres = _mesas.where((m) => m.estado == 'libre').length;
    int ocupadas = _mesas.where((m) => m.estado == 'ocupada').length;
    int reservadas = _mesas.where((m) => m.estado == 'reservada').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Superior
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salón y Mesas', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14))),
                const SizedBox(height: 6),
                Text('Administra en tiempo real la disponibilidad de tu restaurante.', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B635E))),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _abrirModalMesa(),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Nueva Mesa', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E1E39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Barra de Resumen Métrico
        Row(
          children: [
            _buildResumenCard('Capacidad Total', '$capacidadTotal', Icons.people_alt, const Color(0xFF6E1E39)),
            const SizedBox(width: 16),
            _buildResumenCard('Mesas Libres', '$libres', Icons.check_circle, const Color(0xFF2ECC71)),
            const SizedBox(width: 16),
            _buildResumenCard('Mesas Ocupadas', '$ocupadas', Icons.restaurant, const Color(0xFF3498DB)),
            const SizedBox(width: 16),
            _buildResumenCard('Reservadas', '$reservadas', Icons.event_seat, const Color(0xFFF39C12)),
          ],
        ),
        const SizedBox(height: 24),

        // Pestañas / Filtros
        Row(
          children: [
            _buildFiltroPill('Todas', 'todas'),
            const SizedBox(width: 12),
            _buildFiltroPill('Libres', 'libre'),
            const SizedBox(width: 12),
            _buildFiltroPill('Ocupadas', 'ocupada'),
            const SizedBox(width: 12),
            _buildFiltroPill('Reservadas', 'reservada'),
          ],
        ),
        const SizedBox(height: 24),

        // Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
              : mesasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant, size: 64, color: const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),
                          Text('No hay mesas para mostrar.', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFFA39C98))),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 170, // Fixed height for cards
                      ),
                      itemCount: mesasFiltradas.length,
                      itemBuilder: (context, index) {
                        final mesa = mesasFiltradas[index];
                        return _buildMesaCard(mesa);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildResumenCard(String titulo, String valor, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A))),
                Text(titulo, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B635E))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroPill(String label, String valor) {
    final active = _filtroEstado == valor;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = valor),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6E1E39) : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: active ? const Color(0xFF6E1E39) : const Color(0xFFE2E8F0)),
          boxShadow: active ? const [BoxShadow(color: Color(0x336E1E39), blurRadius: 8, offset: Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF6B635E),
          ),
        ),
      ),
    );
  }

  Widget _buildMesaCard(MesaAdminModel mesa) {
    final color = _getColorEstado(mesa.estado);
    final icon = _getIconEstado(mesa.estado);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _cambiarEstadoMesa(mesa),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(mesa.numeroMesa, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A))),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Color(0xFFA39C98), size: 20),
                      onSelected: (val) {
                        if (val == 'edit') _abrirModalMesa(mesa: mesa);
                        if (val == 'delete') _eliminarMesa(mesa.id);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 16, color: Color(0xFF6B635E)), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.manrope(fontSize: 14))])),
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 16, color: Color(0xFFE74C3C)), const SizedBox(width: 8), Text('Eliminar', style: GoogleFonts.manrope(fontSize: 14, color: Color(0xFFE74C3C)))])),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Color(0xFF6B635E)),
                    const SizedBox(width: 6),
                    Text('${mesa.capacidad} Personas', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6B635E), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(mesa.estado.toUpperCase(), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
