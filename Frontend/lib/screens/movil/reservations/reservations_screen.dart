import 'dart:async';
import 'dart:convert';

import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';

part 'mis_reservas/servicio_mis_reservas.dart';
part 'mis_reservas/acciones_reserva.dart';
part '../../../widgets/movil/mis_reservas/pestana_reserva.dart';
part '../../../widgets/movil/mis_reservas/selector_pestanas_reserva.dart';
part '../../../widgets/movil/mis_reservas/estado_vacio_reservas.dart';
part '../../../widgets/movil/mis_reservas/aviso_reservas.dart';
part '../../../widgets/movil/mis_reservas/tarjeta_reserva.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with WidgetsBindingObserver {
  bool _cargando = true;
  bool _mostrarPasadas = false;
  int? _reservaEnCancelacionId;
  String? _mensajeError;
  List<ReservaAdminModel> _reservas = [];
  io.Socket? _socketReservas;
  String? _tokenSocketReservas;
  Timer? _temporizadorLimiteCancelacion;

  List<ReservaAdminModel> get proximas => _reservas
      .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
      .toList();
  List<ReservaAdminModel> get historial => _reservas
      .where((r) => r.estado != 'pendiente' && r.estado != 'confirmada')
      .toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
      _conectarSocketReservas();
    });
  }

  @override
  void didUpdateWidget(covariant ReservationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _cargarReservas();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizadorLimiteCancelacion?.cancel();
    _socketReservas?.disconnect();
    _socketReservas?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _programarAvisoLimiteCancelacion();
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthScope.of(context);
    _conectarSocketReservas();
  }

  @override
  Widget build(BuildContext context) {
    final reservations = _mostrarPasadas ? historial : proximas;
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
            child: SelectorPestanasReserva(
              cantidadProximas: proximas.length,
              cantidadPasadas: historial.length,
              mostrarPasadas: _mostrarPasadas,
              alCambiar: (mostrar) => setState(() => _mostrarPasadas = mostrar),
            ),
          ),
          if (_mensajeError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: InlineErrorBanner(message: _mensajeError!),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ConsumerColors.wine,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarReservas,
                    color: ConsumerColors.wine,
                    child: reservations.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                            children: [
                              EstadoVacioReservas(
                                mostrarPasadas: _mostrarPasadas,
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            children: [
                              for (final reservation in reservations)
                                TarjetaReserva(
                                  reserva: reservation,
                                  puedeCancelar:
                                      (reservation.estado.toLowerCase() ==
                                              'pendiente' ||
                                          reservation.estado.toLowerCase() ==
                                              'confirmada') &&
                                      DateTime.now().isBefore(
                                        _obtenerLimiteCancelacion(reservation),
                                      ),
                                  estaCancelando:
                                      _reservaEnCancelacionId == reservation.id,
                                  onCancelar: _reservaEnCancelacionId == null
                                      ? () => _cancelarReserva(reservation)
                                      : null,
                                ),
                              const SizedBox(height: 4),
                              AvisoReservas(
                                hayPendientes: proximas.any(
                                  (reserva) => reserva.estado == 'pendiente',
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
