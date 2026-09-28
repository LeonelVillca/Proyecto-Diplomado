import 'package:frontend/core/movil/consumer_design.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _isLoading = true;
  bool _showPast = false;
  String? _errorMessage;
  List<ReservaAdminModel> _reservas = [];
  io.Socket? _socket;
  String? _socketToken;

  List<ReservaAdminModel> get proximas => _reservas
      .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
      .toList();
  List<ReservaAdminModel> get historial => _reservas
      .where((r) => r.estado != 'pendiente' && r.estado != 'confirmada')
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
      _conectarSocket();
    });
  }

  @override
  void didUpdateWidget(covariant ReservationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _cargarDatos();
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
    if (token == null) {
      _socket = null;
      return;
    }
    _socket = io.io(ApiEndpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
      'extraHeaders': {'Authorization': 'Bearer $token'},
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
      }
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = AuthScope.of(context, listen: false);
      final idUsuario = auth.idUsuario;
      final token = auth.token;

      if (idUsuario == null) return;

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/reservas/usuario/$idUsuario',
      );
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        _reservas = data.map((e) => ReservaAdminModel.fromJson(e)).toList();
        _reservas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      } else {
        if (mounted)
          setState(() => _errorMessage = 'No se pudieron cargar tus reservas.');
      }
    } catch (e) {
      debugPrint('Error cargando reservas cliente: $e');
      if (mounted)
        setState(() => _errorMessage = 'No se pudieron cargar tus reservas.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservations = _showPast ? historial : proximas;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Volver a Inicio',
                  onPressed: MainShell.openHome,
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Mis reservas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildReservationTabs(context),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: InlineErrorBanner(message: _errorMessage!),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ConsumerColors.wine,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    color: ConsumerColors.wine,
                    child: reservations.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                            children: [_buildEmptyState(context)],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            children: [
                              for (final reservation in reservations)
                                _buildReservaCard(context, reservation),
                              const SizedBox(height: 4),
                              _buildNotice(context),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(color: ConsumerColors.line),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ReservationTab(
              label: 'Próximas',
              count: proximas.length,
              icon: LucideIcons.calendarClock,
              selected: !_showPast,
              onTap: () => setState(() => _showPast = false),
            ),
          ),
          Expanded(
            child: _ReservationTab(
              label: 'Pasadas',
              count: historial.length,
              icon: LucideIcons.history,
              selected: _showPast,
              onTap: () => setState(() => _showPast = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 24),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ConsumerColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: ConsumerColors.paperDeep,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _showPast ? LucideIcons.history : LucideIcons.calendarDays,
              size: 30,
              color: ConsumerColors.wine,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _showPast ? 'Aún no hay reservas pasadas' : 'Sin reservas próximas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _showPast
                ? 'Aquí aparecerá el historial de tus visitas.'
                : 'Descubre un restaurante y reserva una mesa para tu próxima visita.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(BuildContext context, ReservaAdminModel reserva) {
    Widget placeholderRestaurantImage() => const ColoredBox(
      color: ConsumerColors.paperDeep,
      child: Icon(LucideIcons.utensils, color: ConsumerColors.wine),
    );

    Widget restaurantImage() {
      final logo = reserva.restauranteLogo;
      final cover = reserva.restauranteFoto;
      final imageUrl = logo ?? cover;
      if (imageUrl == null || imageUrl.isEmpty) {
        return placeholderRestaurantImage();
      }
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (cover != null && cover.isNotEmpty && cover != imageUrl) {
            return Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholderRestaurantImage(),
            );
          }
          return placeholderRestaurantImage();
        },
      );
    }

    final date = reserva.fechaHora;
    final today = DateTime.now();
    final sameDay =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final tomorrow =
        date.difference(DateTime(today.year, today.month, today.day)).inDays ==
        1;
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final dateLabel = sameDay
        ? 'Hoy'
        : tomorrow
        ? 'Mañana'
        : days[date.weekday - 1] +
              ' ' +
              date.day.toString() +
              ' ' +
              months[date.month - 1];
    final timeLabel =
        date.hour.toString().padLeft(2, '0') +
        ':' +
        date.minute.toString().padLeft(2, '0');
    final status = reserva.estado.toLowerCase();
    final statusColor = status == 'confirmada'
        ? ConsumerColors.success
        : status == 'pendiente'
        ? ConsumerColors.warning
        : status == 'cancelada' || status == 'rechazada'
        ? ConsumerColors.error
        : ConsumerColors.inkSoft;
    final statusBackground = status == 'confirmada'
        ? ConsumerColors.successSoft
        : status == 'pendiente'
        ? ConsumerColors.warningSoft
        : status == 'cancelada' || status == 'rechazada'
        ? ConsumerColors.errorSoft
        : ConsumerColors.paperDeep;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(color: ConsumerColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: restaurantImage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            reserva.restauranteNombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'confirmada')
                                Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: statusColor,
                                ),
                              if (status == 'confirmada')
                                const SizedBox(width: 3),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateLabel + ' · ' + timeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ConsumerColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.users,
                          size: 14,
                          color: ConsumerColors.inkSoft,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          reserva.cantidadPersonas.toString() + ' personas',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((reserva.numeroMesa ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ConsumerColors.paperDeep,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Mesa ' + reserva.numeroMesa!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ConsumerColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (reserva.estado == 'pendiente' ||
              reserva.estado == 'confirmada') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showActionNotice(context, 'reprogramar'),
                    icon: const Icon(LucideIcons.calendarClock, size: 15),
                    label: const Text('Reprogramar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showActionNotice(context, 'cancelar'),
                    icon: const Icon(LucideIcons.x, size: 15),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ConsumerColors.error,
                      side: const BorderSide(color: Color(0xFFF0CFC6)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotice(BuildContext context) {
    final hasPending = proximas.any(
      (reservation) => reservation.estado == 'pendiente',
    );
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(
          color: ConsumerColors.line,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: ConsumerColors.wine,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasPending
                  ? 'Tu solicitud sigue pendiente. Aquí verás cuando el restaurante la confirme.'
                  : 'Puedes consultar aquí el estado y los datos de tus reservas.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionNotice(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('La opción para $action todavía no está disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReservationTab extends StatelessWidget {
  const _ReservationTab({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label, $count',
    child: Material(
      color: selected ? ConsumerColors.wine : Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : ConsumerColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : ConsumerColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .2)
                      : ConsumerColors.paperDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : ConsumerColors.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
