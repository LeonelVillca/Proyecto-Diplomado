part of '../reservation_screen.dart';

extension _ControladorReserva on _ReservationScreenState {
  String _mensajeErrorApi(dynamic response, String fallback) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'];
      if (message is List) return message.join(', ');
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return fallback;
  }

  void _mostrarError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message.replaceFirst('Exception: ', ''));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _comprobarDisponibilidad() async {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return;
    final version = ++_requestVersion;
    final guests = _guests;
    final token = AuthScope.of(context, listen: false).token;
    if (token == null) {
      _mostrarError('Inicia sesión para consultar la disponibilidad.');
      return;
    }
    setState(() {
      _checkingAvailability = true;
      _availableCount = null;
      _errorMessage = null;
    });
    try {
      final tables = await _mesasDisponibles(
        date: date,
        time: time,
        guests: guests,
        token: token,
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _availableCount = tables.length;
        if (tables.isEmpty) {
          _unavailableSlots.add(time);
        } else {
          _unavailableSlots.remove(time);
        }
      });
      if (tables.isEmpty) {
        _mostrarError(
          'No hay mesas disponibles para $guests personas en ese horario. Elige otra hora o fecha.',
        );
      }
    } catch (error) {
      if (mounted && version == _requestVersion)
        _mostrarError(error.toString());
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _checkingAvailability = false);
      }
    }
  }

  Future<void> _actualizarDisponibilidadHorarios() async {
    final date = _selectedDate;
    if (date == null) return;
    final day = _days.where(
      (item) => reservationDateKey(item.date) == reservationDateKey(date),
    );
    if (day.isEmpty || day.first.slots.isEmpty) return;

    final token = AuthScope.of(context, listen: false).token;
    if (token == null) return;
    final slots = List<String>.of(day.first.slots);
    final guests = _guests;
    final version = ++_requestVersion;
    setState(() {
      _checkingAvailability = true;
      _availableCount = null;
      _unavailableSlots.clear();
    });

    try {
      final results = await Future.wait([
        for (final slot in slots)
          _mesasDisponibles(
            date: date,
            time: slot,
            guests: guests,
            token: token,
          ),
      ]);
      if (!mounted || version != _requestVersion) return;
      final unavailable = <String>{};
      for (var index = 0; index < slots.length; index++) {
        if (results[index].isEmpty) unavailable.add(slots[index]);
      }
      setState(() {
        _unavailableSlots
          ..clear()
          ..addAll(unavailable);
        final selectedIndex = _selectedTime == null
            ? -1
            : slots.indexOf(_selectedTime!);
        _availableCount = selectedIndex < 0
            ? null
            : results[selectedIndex].length;
        if (_selectedTime != null && unavailable.contains(_selectedTime)) {
          _selectedTime = null;
          _availableCount = null;
        }
      });
    } catch (_) {
      // El envío vuelve a comprobar disponibilidad antes de crear la reserva.
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _checkingAvailability = false);
      }
    }
  }
}
