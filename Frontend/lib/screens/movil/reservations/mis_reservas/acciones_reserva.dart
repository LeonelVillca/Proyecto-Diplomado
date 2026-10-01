part of '../reservations_screen.dart';

extension _AccionesReserva on _ReservationsScreenState {
  Future<void> _cancelarReserva(ReservaAdminModel reserva) async {
    if (_reservaEnCancelacionId != null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text(
          '¿Quieres cancelar esta reserva? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;
    if (!DateTime.now().isBefore(_obtenerLimiteCancelacion(reserva))) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo puedes cancelar hasta 15 minutos antes de la reserva.',
          ),
        ),
      );
      return;
    }

    setState(() => _reservaEnCancelacionId = reserva.id);
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/reservas/${reserva.id}/cancelar',
        ),
        headers: {
          'Authorization':
              'Bearer ${AuthScope.of(context, listen: false).token}',
        },
      );
      if (response.statusCode != 200) {
        String message = 'No se pudo cancelar la reserva.';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map && body['message'] is String) {
            message = body['message'] as String;
          }
        } catch (_) {}
        throw StateError(message);
      }
      await _cargarReservas();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reserva cancelada.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is StateError
            ? error.message
            : 'No se pudo cancelar la reserva. Inténtalo nuevamente.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _reservaEnCancelacionId = null);
    }
  }
}
