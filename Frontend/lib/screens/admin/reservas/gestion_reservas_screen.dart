import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class GestionReservasScreen extends StatefulWidget {
  const GestionReservasScreen({super.key});

  @override
  State<GestionReservasScreen> createState() => _GestionReservasScreenState();
}

class _GestionReservasScreenState extends State<GestionReservasScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  int? _idRestaurante;
  List<ReservaAdminModel> _reservas = [];
  io.Socket? _socket;
  String? _socketToken;
  String _filtroEstado = 'todas';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthScope.of(context);
    if (_idRestaurante != null) _conectarSocket();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _conectarSocket() {
    final token = AuthScope.of(context, listen: false).token;
    if (token == _socketToken && _socket != null) return;
    _socket?.dispose();
    _socketToken = token;
    if (token == null) { _socket = null; return; }
    _socket = io.io(ApiEndpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    _socket!.connect();
    
    _socket!.onConnect((_) {
      debugPrint('Websocket conectado para reservas');
    });

    _socket!.on('nueva_reserva', (data) {
      if (data['idRestaurante'] == _idRestaurante) {
        if (mounted) {
          AdminNotificationModal.success(context, '¡Nueva reserva entrante!');
          _cargarDatos();
        }
      }
    });

    _socket!.on('reserva_actualizada', (data) {
       if (data['idRestaurante'] == _idRestaurante) {
         if (mounted) _cargarDatos();
       }
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context).token;

      // Obtener restaurante
      final urlRest = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final resRest = await http.get(urlRest, headers: {'Authorization': 'Bearer $token'});

      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(utf8.decode(resRest.bodyBytes));
        if (dataRest.isNotEmpty) {
          _idRestaurante = dataRest.first['id'];
          
          if (_socket == null) {
            _conectarSocket();
          }

          // Obtener reservas
          final urlReservas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$_idRestaurante');
          final resReservas = await http.get(urlReservas, headers: {'Authorization': 'Bearer $token'});

          if (resReservas.statusCode == 200) {
            final List<dynamic> dataReservas = jsonDecode(utf8.decode(resReservas.bodyBytes));
            _reservas = dataReservas.map((e) => ReservaAdminModel.fromJson(e)).toList();
            _reservas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando reservas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstadoReserva(ReservaAdminModel reserva, String nuevoEstado) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final res = await http.patch(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/${reserva.id}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (res.statusCode == 200) {
        await _cargarDatos();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return const Color(0xFF2ECC71);
      case 'pendiente':
        return const Color(0xFFF39C12);
      case 'rechazada':
      case 'cancelada':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getIconEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return Icons.check_circle_rounded;
      case 'pendiente':
        return Icons.access_time_rounded;
      case 'rechazada':
      case 'cancelada':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
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

  Widget _buildResumenCard(String titulo, String valor, IconData icon, Color color) {
    return Container(
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
      );
  }

  @override
  Widget build(BuildContext context) {
    final reservasFiltradas = _filtroEstado == 'todas' 
        ? _reservas 
        : _reservas.where((r) => 
            (_filtroEstado == 'confirmada' && r.estado == 'confirmada') ||
            (_filtroEstado == 'rechazada' && (r.estado == 'rechazada' || r.estado == 'cancelada')) ||
            (r.estado == _filtroEstado)
          ).toList();

    int totalPendientes = _reservas.where((r) => r.estado == 'pendiente').length;
    int totalConfirmadas = _reservas.where((r) => r.estado == 'confirmada').length;
    int totalPersonasHoy = _reservas
        .where((r) => r.estado == 'confirmada' &&
                       r.fechaHora.day == DateTime.now().day &&
                       r.fechaHora.month == DateTime.now().month)
        .fold(0, (sum, r) => sum + r.cantidadPersonas);

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          kicker: 'OPERACIÓN',
          titleBefore: 'Gestión de ',
          titleEmphasis: 'Reservas',
          description: 'Administra las reservas entrantes y sus estados.',
          actions: const [AdminStatusChip(status: AdminStatus.active, label: 'Conectado')],
        ),
        const SizedBox(height: 24),

        // Barra de Resumen Métrico
        LayoutBuilder(builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: constraints.maxWidth < 760 ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 24) / 3, child: _buildResumenCard('Nuevas Pendientes', '$totalPendientes', Icons.access_time_filled, AdminTheme.warning)),
            SizedBox(width: constraints.maxWidth < 760 ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 24) / 3, child: _buildResumenCard('Confirmadas Total', '$totalConfirmadas', Icons.check_circle_outline, AdminTheme.success)),
            SizedBox(width: constraints.maxWidth < 760 ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 24) / 3, child: _buildResumenCard('Personas (Hoy)', '$totalPersonasHoy', Icons.people_alt_outlined, AdminTheme.accentColor)),
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
            _buildFiltroPill('Pendientes', 'pendiente'),
            _buildFiltroPill('Confirmadas', 'confirmada'),
            _buildFiltroPill('Rechazadas', 'rechazada'),
          ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid
        Expanded(
          child: AdminSurface(
            child: _isLoading && _reservas.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
              : reservasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: const Color(0xFFE2E8F0)),
                          const SizedBox(height: 16),
                          Text('No hay reservas para mostrar.', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFFA39C98))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: reservasFiltradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reserva = reservasFiltradas[index];
                        final fechaFormat = '${reserva.fechaHora.day.toString().padLeft(2,'0')}/${reserva.fechaHora.month.toString().padLeft(2,'0')}/${reserva.fechaHora.year} a las ${reserva.fechaHora.hour.toString().padLeft(2,'0')}:${reserva.fechaHora.minute.toString().padLeft(2,'0')}';
                        
                        final color = _getColorEstado(reserva.estado);
                        final icon = _getIconEstado(reserva.estado);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 5))],
                            border: Border.all(color: reserva.estado == 'pendiente' ? const Color(0xFFF39C12).withValues(alpha: 0.3) : const Color(0xFFF1F5F9)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(icon, color: color, size: 28),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mesa  • $fechaFormat',
                                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B1A)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.group, size: 16, color: Color(0xFF6B635E)),
                                          const SizedBox(width: 6),
                                          Text('${reserva.cantidadPersonas} Personas', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B635E), fontWeight: FontWeight.w600)),
                                          if (reserva.requerimientosEspeciales != null && reserva.requerimientosEspeciales!.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B635E)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                reserva.requerimientosEspeciales!,
                                                style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B635E)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    reserva.estado.toUpperCase(),
                                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                if (reserva.estado == 'pendiente') ...[
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : () => _cambiarEstadoReserva(reserva, 'confirmada'),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: Text('Confirmar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading ? null : () => _cambiarEstadoReserva(reserva, 'rechazada'),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: Text('Rechazar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE74C3C),
                                      side: const BorderSide(color: Color(0xFFE74C3C)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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



