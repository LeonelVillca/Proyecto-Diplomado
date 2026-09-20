import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';
import 'package:frontend/services/movil/notification_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _isLoading = true;
  List<ReservaAdminModel> _reservas = [];
  io.Socket? _socket;
  String? _socketToken;
  
  List<ReservaAdminModel> get proximas => _reservas.where((r) => r.estado == 'pendiente' || r.estado == 'confirmada' || r.estado == 'aprobada').toList();
  List<ReservaAdminModel> get historial => _reservas.where((r) => r.estado != 'pendiente' && r.estado != 'confirmada' && r.estado != 'aprobada').toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
      _conectarSocket();
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthScope.of(context);
    _conectarSocket();
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
      debugPrint('Websocket conectado para el cliente');
    });

    _socket!.on('nueva_reserva', (data) {
       final auth = AuthScope.of(context, listen: false);
       if (data['idUsuario'] == auth.idUsuario) {
         if (mounted) _cargarDatos();
       }
    });

    _socket!.on('reserva_actualizada', (data) {
       // El backend envía {id, estado, idRestaurante}
       bool belongsToUser = _reservas.any((r) => r.id == data['id']);
       if (belongsToUser) {
         if (mounted) _cargarDatos();
         
         // Lanzar notificacion
         final status = data['estado']?.toString() ?? 'actualizada';
         final notif = NotificationService();
         notif.showNotification(
           id: data['id'] ?? 0,
           title: 'Reserva $status',
           body: 'El estado de tu reserva ha cambiado a $status.',
         );
       }
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = AuthScope.of(context, listen: false);
      final idUsuario = auth.idUsuario;
      final token = auth.token;
      
      if (idUsuario == null) return;

      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/usuario/$idUsuario');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        _reservas = data.map((e) => ReservaAdminModel.fromJson(e)).toList();
        _reservas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

        // Programar notificaciones para reservas próximas
        final notif = NotificationService();
        final now = DateTime.now();
        for (var r in _reservas) {
          if (r.estado == 'aprobada' || r.estado == 'confirmada') {
            final scheduleTime = r.fechaHora.subtract(const Duration(minutes: 30));
            if (scheduleTime.isAfter(now)) {
              notif.scheduleNotification(
                id: r.id, 
                title: 'Reserva próxima en ${r.restauranteNombre}',
                body: 'Tu reserva es en 30 minutos. ¡Prepárate!', 
                scheduledDate: scheduleTime
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando reservas cliente: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis reservas', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28)),
                  const SizedBox(height: 24),
                  
                  // Tarjetas de estadisticas
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, proximas.length.toString(), 'Próximas', Icons.event_available_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(context, historial.length.toString(), 'Historial', Icons.history_rounded)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.wine))
                      : proximas.isEmpty && historial.isEmpty
                          ? _buildEmptyState(context)
                          : _buildReservasList(context),
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.cardSoft),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.paperDeep, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_rounded, size: 36, color: AppColors.wine),
          ),
          const SizedBox(height: 24),
          Text('Sin reservas próximas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Parece que aún no tienes planes. ¡Descubre un nuevo lugar para comer hoy!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildReservasList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (proximas.isNotEmpty) ...[
          Text('Próximas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...proximas.map((r) => _buildReservaCard(context, r)).toList(),
          const SizedBox(height: 24),
        ],
        if (historial.isNotEmpty) ...[
          Text('Historial', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...historial.map((r) => _buildReservaCard(context, r)).toList(),
        ],
      ],
    );
  }

  Widget _buildReservaCard(BuildContext context, ReservaAdminModel reserva) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade700;
    
    if (reserva.estado == 'aprobada' || reserva.estado == 'confirmada') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (reserva.estado == 'pendiente') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    } else if (reserva.estado == 'rechazada' || reserva.estado == 'cancelada') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }

    final date = reserva.fechaHora;
    final fechaStr = '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')} a las ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.cardSoft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.paperDeep, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.restaurant_rounded, color: AppColors.wine),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reserva.restauranteNombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(fechaStr, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 14, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text('${reserva.cantidadPersonas} personas', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(reserva.estado.toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.cardSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.wine, size: 24),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
