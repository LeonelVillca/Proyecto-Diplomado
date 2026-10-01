part of '../gestion_mesas_screen.dart';

extension _ControladorMesas on _GestionMesasScreenState {
  void _recalcularHorariosDisponibles() {
    final now = DateTime.now();
    final selectedDay = DateTime(
      _fechaConsulta.year,
      _fechaConsulta.month,
      _fechaConsulta.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final scheduleNow = selectedDay == today ? now : selectedDay;
    final days = reservationDays(
      now: scheduleNow,
      weekly: _horariosSemana,
      exceptions: _excepcionesHorario,
      horizonDays: 1,
      durationMinutes: 60,
    );
    _horariosDisponibles = days.isEmpty ? [] : days.first.slots;
    final current24 =
        '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';
    if (!_horariosDisponibles.contains(current24)) {
      final defaultTime = _horariosDisponibles.isEmpty
          ? null
          : _horariosDisponibles.contains('14:00')
          ? '14:00'
          : _horariosDisponibles.first;
      if (defaultTime != null) {
        final parts = defaultTime.split(':').map(int.parse).toList();
        _horaConsulta = TimeOfDay(hour: parts[0], minute: parts[1]);
      }
    }
  }

  String _estadoEnConsulta(Map<String, dynamic> mesa) {
    if (mesa['estado'] == 'inactiva') return 'inactiva';
    if (mesa['reserva'] != null) return 'reservada';
    return (mesa['estado'] as String?) ?? 'libre';
  }

  List<String> _slotsParaFecha(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final scheduleNow = isToday
        ? now
        : DateTime(date.year, date.month, date.day);
    final days = reservationDays(
      now: scheduleNow,
      weekly: _horariosSemana,
      exceptions: _excepcionesHorario,
      horizonDays: 1,
      durationMinutes: 60,
    );
    return days.isEmpty ? const [] : days.first.slots;
  }

  bool _tieneAtencionConfigurada(DateTime date) {
    final key = reservationDateKey(date);
    final exception = _excepcionesHorario.where((item) => item.date == key);
    if (exception.isNotEmpty) {
      final special = exception.first;
      return !special.closed && special.start != null && special.end != null;
    }
    return _horariosSemana.any((hours) => hours.weekday == date.weekday - 1);
  }

  Future<void> _seleccionarDia(DateTime date) async {
    setState(() {
      _fechaConsulta = DateTime(date.year, date.month, date.day);
      _horariosDisponibles = this._slotsParaFecha(_fechaConsulta);
      this._recalcularHorariosDisponibles();
    });
    await this._consultarOcupacion();
  }

  int _countForState(String state) =>
      _ocupacion.where((mesa) => this._estadoEnConsulta(mesa) == state).length;

  Future<void> _cambiarEstadoMesa(Map<String, dynamic> datosMesa) async {
    final idMesa = (datosMesa['idMesa'] as num).toInt();
    if (_mesasActualizando.contains(idMesa)) return;
    final estado = this._estadoEnConsulta(datosMesa);
    String nuevoEstado = 'libre';
    if (estado == 'libre') {
      nuevoEstado = 'ocupada';
    } else if (estado == 'ocupada') {
      nuevoEstado = 'reservada';
    } else if (estado == 'reservada') {
      nuevoEstado = 'libre';
    } else if (estado == 'inactiva' || datosMesa['reserva'] != null) {
      return;
    }

    final originalOcupacion = [
      for (final item in _ocupacion) Map<String, dynamic>.from(item),
    ];
    final fecha = reservationDateKey(_fechaConsulta);
    final hora =
        datosMesa['bloqueoHora'] as String? ??
        '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';
    setState(() {
      _mesasActualizando.add(idMesa);
      _ocupacion = [
        for (final item in _ocupacion)
          if (item['idMesa'] == idMesa)
            {
              ...item,
              'estado': nuevoEstado,
              'disponible': nuevoEstado == 'libre',
              'bloqueoHora': nuevoEstado == 'libre' ? null : hora,
            }
          else
            item,
      ];
    });

    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/mesa/$idMesa/estado-horario',
      );
      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fecha': fecha, 'hora': hora, 'estado': nuevoEstado}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final message = body is Map ? body['message'] : null;
        throw Exception(
          message is String
              ? message
              : 'No se pudo actualizar la mesa (HTTP ${res.statusCode}).',
        );
      }
      await this._consultarOcupacion(token: token);
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _ocupacion = originalOcupacion);
        AdminNotificationModal.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _mesasActualizando.remove(idMesa));
    }
  }

  void _abrirModalMesa({MesaAdminModel? mesa}) {
    if (_idRestaurante == null) {
      AdminNotificationModal.info(
        context,
        'No tienes un restaurante asociado.',
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final numeroCtrl = TextEditingController(text: mesa?.numeroMesa ?? '');
    final capacidadCtrl = TextEditingController(
      text: mesa?.capacidad.toString() ?? '4',
    );
    String estadoSeleccionado = mesa?.estado == 'inactiva'
        ? 'inactiva'
        : 'libre';

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
          this._guardarMesa(body, mesa?.id);
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: capacidadCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: AdminInputDecoration.get(
                labelText: 'Capacidad de Personas',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty || int.tryParse(v) == null
                  ? 'Número válido requerido'
                  : null,
            ),
            if (mesa != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: estadoSeleccionado,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF1E1B1A),
                  fontSize: 14,
                ),
                decoration: AdminInputDecoration.get(
                  labelText: 'Estado general',
                ),
                items: const [
                  DropdownMenuItem(value: 'libre', child: Text('Libre')),
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
}
