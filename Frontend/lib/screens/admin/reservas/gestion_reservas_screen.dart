import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';

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
  String _filtroEstado = 'todas';

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
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _conectarSocket() {
    final token = AuthScope.of(context).token;
    _socket = io.io(ApiEndpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    _socket!.connect();
    
    _socket!.onConnect((_) {
      debugPrint('Websocket conectado para reservas');
    });

    _socket!.on('nueva_reserva', (data) {
      if (data['idRestaurante'] == _idRestaurante) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Nueva reserva entrante!'), 
              backgroundColor: const Color(0xFF2ECC71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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
      case 'aprobada':
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
      case 'aprobada':
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
                Text(valor, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A))),
                Text(titulo, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B635E))),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservasFiltradas = _filtroEstado == 'todas' 
        ? _reservas 
        : _reservas.where((r) => 
            (_filtroEstado == 'confirmada' && (r.estado == 'confirmada' || r.estado == 'aprobada')) ||
            (_filtroEstado == 'rechazada' && (r.estado == 'rechazada' || r.estado == 'cancelada')) ||
            (r.estado == _filtroEstado)
          ).toList();

    int totalPendientes = _reservas.where((r) => r.estado == 'pendiente').length;
    int totalConfirmadas = _reservas.where((r) => r.estado == 'confirmada' || r.estado == 'aprobada').length;
    int totalPersonasHoy = _reservas
        .where((r) => (r.estado == 'confirmada' || r.estado == 'aprobada') && 
                       r.fechaHora.day == DateTime.now().day &&
                       r.fechaHora.month == DateTime.now().month)
        .fold(0, (sum, r) => sum + r.cantidadPersonas);

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
                Text('Reservas en Tiempo Real', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14))),
                const SizedBox(height: 6),
                Text('Administra las reservas entrantes. Actualización en vivo activada.', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B635E))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF2ECC71).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3))),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Conectado', style: GoogleFonts.manrope(color: const Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Barra de Resumen Métrico
        Row(
          children: [
            _buildResumenCard('Nuevas Pendientes', '$totalPendientes', Icons.access_time_filled, const Color(0xFFF39C12)),
            const SizedBox(width: 16),
            _buildResumenCard('Confirmadas Total', '$totalConfirmadas', Icons.check_circle, const Color(0xFF2ECC71)),
            const SizedBox(width: 16),
            _buildResumenCard('Personas (Hoy)', '$totalPersonasHoy', Icons.people_alt, const Color(0xFF3498DB)),
          ],
        ),
        const SizedBox(height: 24),

        // Pestañas / Filtros
        Row(
          children: [
            _buildFiltroPill('Todas', 'todas'),
            const SizedBox(width: 12),
            _buildFiltroPill('Pendientes', 'pendiente'),
            const SizedBox(width: 12),
            _buildFiltroPill('Confirmadas', 'confirmada'),
            const SizedBox(width: 12),
            _buildFiltroPill('Rechazadas', 'rechazada'),
          ],
        ),
        const SizedBox(height: 24),

        // Grid
        Expanded(
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
                                        'Mesa ${reserva.idMesa} â€¢ $fechaFormat',
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
                                    onPressed: () => _cambiarEstadoReserva(reserva, 'confirmada'),
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
                                    onPressed: () => _cambiarEstadoReserva(reserva, 'rechazada'),
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
      ],
    );
  }
}



