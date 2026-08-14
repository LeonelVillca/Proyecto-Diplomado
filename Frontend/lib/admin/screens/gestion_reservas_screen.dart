import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/reserva_admin_model.dart';

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
            const SnackBar(content: Text('¡Nueva reserva entrante!'), backgroundColor: Colors.green),
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

  Widget _buildBadge(String estado) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade700;
    
    if (estado == 'aprobada' || estado == 'confirmada') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (estado == 'pendiente') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    } else if (estado == 'rechazada' || estado == 'cancelada') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
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
                  'Reservas en Tiempo Real',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra las reservas entrantes. Actualización en vivo activada.',
                  style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Conectado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading && _reservas.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _reservas.isEmpty
                  ? Center(child: Text('No hay reservas registradas.', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.separated(
                      itemCount: _reservas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reserva = _reservas[index];
                        final fechaFormat = '${reserva.fechaHora.day.toString().padLeft(2,'0')}/${reserva.fechaHora.month.toString().padLeft(2,'0')}/${reserva.fechaHora.year} ${reserva.fechaHora.hour.toString().padLeft(2,'0')}:${reserva.fechaHora.minute.toString().padLeft(2,'0')}';

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
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.event, color: Colors.blue.shade700),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Mesa ID: ${reserva.idMesa} • $fechaFormat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Karla')),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Personas: ${reserva.cantidadPersonas} ${reserva.requerimientosEspeciales != null ? '• Nota: ${reserva.requerimientosEspeciales}' : ''}',
                                        style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildBadge(reserva.estado),
                                const SizedBox(width: 24),
                                if (reserva.estado == 'pendiente') ...[
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                    tooltip: 'Confirmar Reserva',
                                    onPressed: () => _cambiarEstadoReserva(reserva, 'confirmada'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                                    tooltip: 'Rechazar Reserva',
                                    onPressed: () => _cambiarEstadoReserva(reserva, 'rechazada'),
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
