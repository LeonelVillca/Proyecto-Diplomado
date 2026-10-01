part of '../reservation_screen.dart';

extension _ServicioReserva on _ReservationScreenState {
  Future<void> _cargarOpciones() async {
    if (!mounted) return;
    setState(() {
      _loadingOptions = true;
      _days = [];
      _selectedDate = null;
      _selectedTime = null;
      _availableCount = null;
      _checkingAvailability = false;
      _requestVersion++;
      _errorMessage = null;
    });
    try {
      final token = AuthScope.of(context, listen: false).token;
      if (token == null) {
        throw Exception('Inicia sesión para consultar los horarios.');
      }
      final headers = {'Authorization': 'Bearer $token'};
      final base = ApiEndpoints.baseUrl;
      final id = widget.restaurant.id;
      final responses = await Future.wait([
        http.get(
          Uri.parse('$base/api/v1/horario-atencion/restaurante/$id'),
          headers: headers,
        ),
        http.get(
          Uri.parse(
            '$base/api/v1/horario-atencion/excepciones/restaurante/$id',
          ),
          headers: headers,
        ),
        http.get(
          Uri.parse('$base/api/v1/mesa/restaurante/$id'),
          headers: headers,
        ),
      ]);
      if (responses[0].statusCode != 200) {
        throw Exception(
          _mensajeErrorApi(responses[0], 'No se pudieron cargar los horarios.'),
        );
      }
      if (responses[1].statusCode != 200) {
        throw Exception(
          _mensajeErrorApi(
            responses[1],
            'No se pudieron cargar los días especiales.',
          ),
        );
      }
      if (responses[2].statusCode != 200) {
        throw Exception(
          _mensajeErrorApi(responses[2], 'No se pudieron cargar las mesas.'),
        );
      }

      final weeklyData =
          jsonDecode(utf8.decode(responses[0].bodyBytes)) as List<dynamic>;
      final exceptionData =
          jsonDecode(utf8.decode(responses[1].bodyBytes)) as List<dynamic>;
      final tableData =
          jsonDecode(utf8.decode(responses[2].bodyBytes)) as List<dynamic>;
      final weekly = [
        for (final item in weeklyData)
          WeeklyHours(
            weekday: (item['diaSemana'] as num).toInt(),
            start: item['horaInicio'] as String,
            end: item['horaFin'] as String,
          ),
      ];
      final exceptions = [
        for (final item in exceptionData)
          HoursException(
            date: item['fecha'] as String,
            closed: item['cerrado'] as bool,
            start: item['horaInicio'] as String?,
            end: item['horaFin'] as String?,
          ),
      ];
      final dates = reservationDays(
        now: DateTime.now(),
        weekly: weekly,
        exceptions: exceptions,
        durationMinutes: _durationMinutes,
      );
      final capacities = [
        for (final table in tableData)
          if (table['estado'] != 'inactiva')
            (table['capacidad'] as num?)?.toInt() ?? 0,
      ];
      final maximum = capacities.isEmpty
          ? 0
          : capacities.reduce((a, b) => a > b ? a : b);
      if (!mounted) return;
      setState(() {
        _days = dates.take(7).toList();
        _selectedDate = dates.isEmpty ? null : dates.first.date;
        _selectedTime = null;
        _maxGuests = maximum > 8 ? 8 : maximum;
        if (_maxGuests > 0 && _guests > _maxGuests) _guests = _maxGuests;
        _availableCount = null;
        _requestVersion++;
      });
      _actualizarDisponibilidadHorarios();
    } catch (error) {
      _mostrarError(error.toString());
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<List<dynamic>> _mesasDisponibles({
    required DateTime date,
    required String time,
    required int guests,
    required String token,
  }) async {
    final url =
        Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/reservas/disponibilidad',
        ).replace(
          queryParameters: {
            'idRestaurante': widget.restaurant.id,
            'fecha': reservationDateKey(date),
            'hora': time,
            'numeroPersonas': guests.toString(),
            'duracionMinutos': _durationMinutes.toString(),
          },
        );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        _mensajeErrorApi(response, 'No se pudo consultar la disponibilidad.'),
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['mesas'] as List<dynamic>;
  }

  Future<void> _enviarReserva() async {
    if (_submitting) return;
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) {
      _mostrarError('Selecciona una fecha y una hora para continuar.');
      return;
    }
    final guests = _guests;
    final auth = AuthScope.of(context, listen: false);
    final userId = auth.idUsuario;
    final token = auth.token;
    if (userId == null || token == null) {
      _mostrarError('Inicia sesión para solicitar una reserva.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      // La comprobación se repite aunque ya se haya mostrado una vista previa.
      final tables = await _mesasDisponibles(
        date: date,
        time: time,
        guests: guests,
        token: token,
      );
      if (tables.isEmpty) {
        throw Exception(
          'No hay mesas disponibles para $guests personas en ese horario. Elige otra hora o fecha.',
        );
      }
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idUsuario': userId,
          'idMesa': (tables.first['idMesa'] as num).toInt(),
          'fecha': reservationDateKey(date),
          'hora': time,
          'duracionMinutos': _durationMinutes,
          'numeroPersonas': guests,
          if (_commentController.text.trim().isNotEmpty)
            'comentarios': _commentController.text.trim(),
        }),
      );
      if (response.statusCode != 201) {
        throw Exception(
          _mensajeErrorApi(response, 'No se pudo crear la reserva.'),
        );
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ReservationSentScreen(
            restaurant: widget.restaurant,
            date: _fechaLarga(date),
            time: time,
            guests: guests,
            onMyReservations: () {
              MainShell.openReservations();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } catch (error) {
      _mostrarError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
