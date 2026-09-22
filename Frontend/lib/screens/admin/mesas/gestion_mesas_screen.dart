import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/mesa_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

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
      if (mounted) AdminNotificationModal.error(context, 'No pudimos cambiar el estado de la mesa.');
    }
  }

  void _abrirModalMesa({MesaAdminModel? mesa}) {
    if (_idRestaurante == null) {
      AdminNotificationModal.info(context, 'No tienes un restaurante asociado.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroCtrl = TextEditingController(text: mesa?.numeroMesa ?? '');
    final capacidadCtrl = TextEditingController(text: mesa?.capacidad.toString() ?? '4');
    String estadoSeleccionado = mesa?.estado ?? 'libre';

    AdminModal.show(
      context: context,
      title: mesa == null ? 'Nueva Mesa' : 'Editar Mesa',
      confirmText: mesa == null ? 'Crear Mesa' : 'Guardar Cambios',
      onConfirm: () async {
        if (formKey.currentState!.validate()) {
          final body = {
            'idRestaurante': _idRestaurante,
            'numeroMesa': numeroCtrl.text.trim(),
            'capacidad': int.parse(capacidadCtrl.text.trim()),
            'estado': estadoSeleccionado,
          };
          Navigator.pop(context);
          _guardarMesa(body, mesa?.id);
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: numeroCtrl,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: AdminInputDecoration.get(
                labelText: 'Identificador (Ej: Mesa 1, Barra 2)',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: capacidadCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: AdminInputDecoration.get(
                labelText: 'Capacidad de Personas',
              ),
              validator: (v) => v == null || v.trim().isEmpty || int.tryParse(v) == null ? 'Número válido requerido' : null,
            ),
            if (mesa != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: estadoSeleccionado,
                style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A), fontSize: 14),
                decoration: AdminInputDecoration.get(
                  labelText: 'Estado Inicial',
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
          AdminNotificationModal.success(context, 'Mesa guardada exitosamente');
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) AdminNotificationModal.error(context, 'No pudimos guardar la mesa.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMesa(int id) async {
    final conf = await AdminModal.show<bool>(
      context: context,
      title: 'Eliminar Mesa',
      confirmText: 'Eliminar',
      confirmColor: const Color(0xFFE74C3C),
      onConfirm: () => Navigator.pop(context, true),
      content: Text('¿Seguro que deseas eliminar esta mesa permanentemente?', style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A))),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          kicker: 'SALÓN',
          titleBefore: 'Gestión de ',
          titleEmphasis: 'Mesas',
          description: 'Administra la disponibilidad y capacidad de tu restaurante.',
          actions: [
            FilledButton.icon(onPressed: () => _abrirModalMesa(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nueva mesa')),
          ],
        ),
        const SizedBox(height: 24),

        // Barra de Resumen Métrico
        LayoutBuilder(builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildResumenCard('Capacidad Total', '$capacidadTotal', Icons.people_alt_outlined, AdminTheme.primaryColor, constraints.maxWidth),
            _buildResumenCard('Mesas Libres', '$libres', Icons.check_circle_outline, AdminTheme.success, constraints.maxWidth),
            _buildResumenCard('Mesas Ocupadas', '$ocupadas', Icons.restaurant_outlined, AdminTheme.accentColor, constraints.maxWidth),
            _buildResumenCard('Reservadas', '$reservadas', Icons.event_seat_outlined, AdminTheme.warning, constraints.maxWidth),
          ],
        )),
        const SizedBox(height: 24),

        // Pestañas / Filtros
        AdminSurface(
          padding: const EdgeInsets.all(10),
          radius: AdminTheme.mediumRadius,
          child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFiltroPill('Todas', 'todas'),
            _buildFiltroPill('Libres', 'libre'),
            _buildFiltroPill('Ocupadas', 'ocupada'),
            _buildFiltroPill('Reservadas', 'reservada'),
          ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid
        Expanded(
          child: AdminSurface(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
              : mesasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.table_restaurant_outlined, size: 64, color: AdminTheme.border),
                          const SizedBox(height: 16),
                          Text('No hay mesas para mostrar.', style: AdminTheme.bodyStyle),
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
        ),
      ],
      ),
    );
  }

  Widget _buildResumenCard(String titulo, String valor, IconData icon, Color color, double availableWidth) {
    return SizedBox(
      width: availableWidth < 760 ? (availableWidth - 12) / 2 : (availableWidth - 36) / 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: AdminTheme.mediumRadius,
          border: Border.all(color: AdminTheme.border),
          boxShadow: AdminTheme.shadowSm,
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
                Text(valor, style: AdminTheme.titleStyle.copyWith(fontSize: 24)),
                Text(titulo, style: AdminTheme.bodyStyle.copyWith(fontSize: 12)),
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
          color: active ? AdminTheme.primaryColor : AdminTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: active ? AdminTheme.primaryColor : AdminTheme.border),
          boxShadow: active ? AdminTheme.shadowSm : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AdminTheme.textMuted,
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
        color: AdminTheme.surface,
        borderRadius: AdminTheme.mediumRadius,
        boxShadow: AdminTheme.shadowSm,
        border: Border.all(color: AdminTheme.border),
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



