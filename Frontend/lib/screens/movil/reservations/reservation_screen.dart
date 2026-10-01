import 'package:frontend/core/movil/consumer_design.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/screens/movil/reservations/reservation_schedule.dart';
import 'package:frontend/screens/movil/reservations/reservation_sent_screen.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';

part 'reserva/servicio_reserva.dart';
part 'reserva/controlador_reserva.dart';
part '../../../widgets/movil/reservas/resumen_restaurante.dart';
part '../../../widgets/movil/reservas/selector_fechas_reserva.dart';
part '../../../widgets/movil/reservas/selector_horarios_reserva.dart';
part '../../../widgets/movil/reservas/selector_comensales.dart';
part '../../../widgets/movil/reservas/campo_peticiones_especiales.dart';
part '../../../widgets/movil/reservas/barra_confirmacion_reserva.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  static const int _durationMinutes = 60;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<ReservationDay> _days = [];
  DateTime? _selectedDate;
  String? _selectedTime;
  int _guests = 2;
  int _maxGuests = 0;
  int? _availableCount;
  final Set<String> _unavailableSlots = {};
  int _requestVersion = 0;
  bool _loadingOptions = true;
  bool _checkingAvailability = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarOpciones());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days
        .where(
          (day) =>
              _selectedDate != null &&
              reservationDateKey(day.date) ==
                  reservationDateKey(_selectedDate!),
        )
        .toList();
    final slots = selectedDay.isEmpty ? <String>[] : selectedDay.first.slots;
    final canSubmit =
        !_submitting &&
        !_loadingOptions &&
        !_checkingAvailability &&
        _selectedDate != null &&
        _selectedTime != null &&
        !_unavailableSlots.contains(_selectedTime) &&
        _maxGuests > 0;

    return Scaffold(
      backgroundColor: ConsumerColors.paper,
      appBar: AppBar(title: const Text('Reservar una mesa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  InlineErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 14),
                ],
                ResumenRestauranteReserva(pantalla: this),
                SelectorFechasReserva(pantalla: this),
                SelectorHorariosReserva(pantalla: this, horarios: slots),
                SelectorComensalesReserva(pantalla: this),
                CampoPeticionesReserva(pantalla: this),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BarraConfirmacionReserva(
        pantalla: this,
        habilitada: canSubmit,
      ),
    );
  }
}
