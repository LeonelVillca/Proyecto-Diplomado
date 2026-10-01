part of '../reservations_screen.dart';

extension _ServicioMisReservas on _ReservationsScreenState {
  DateTime _obtenerLimiteCancelacion(ReservaAdminModel reserva) =>
      reserva.cancelarHasta ??
      reserva.fechaHora.subtract(const Duration(minutes: 15));

  void _programarAvisoLimiteCancelacion() {
    _temporizadorLimiteCancelacion?.cancel();
    final now = DateTime.now();
    final limites =
        proximas
            .map(_obtenerLimiteCancelacion)
            .where((limite) => limite.isAfter(now))
            .toList()
          ..sort();
    if (limites.isEmpty) return;
    _temporizadorLimiteCancelacion = Timer(limites.first.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _programarAvisoLimiteCancelacion();
    });
  }

  void _conectarSocketReservas() {
    final token = AuthScope.of(context, listen: false).token;
    if (token == _tokenSocketReservas && _socketReservas != null) return;
    _socketReservas?.dispose();
    _tokenSocketReservas = token;
    if (token == null) {
      _socketReservas = null;
      return;
    }
    _socketReservas = io.io(ApiEndpoints.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    _socketReservas!.connect();

    _socketReservas!.onConnect((_) {
      debugPrint('Websocket conectado para el cliente');
    });

    _socketReservas!.on('nueva_reserva', (data) {
      final auth = AuthScope.of(context, listen: false);
      if (data['idUsuario'] == auth.idUsuario) {
        if (mounted) _cargarReservas();
      }
    });

    _socketReservas!.on('reserva_actualizada', (data) {
      // El backend envía {id, estado, idRestaurante}
      bool belongsToUser = _reservas.any((r) => r.id == data['id']);
      if (belongsToUser) {
        if (mounted) _cargarReservas();
      }
    });
  }

  Future<void> _cargarReservas() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _mensajeError = null;
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
        _programarAvisoLimiteCancelacion();
      } else {
        if (mounted)
          setState(() => _mensajeError = 'No se pudieron cargar tus reservas.');
      }
    } catch (e) {
      debugPrint('Error cargando reservas cliente: $e');
      if (mounted)
        setState(() => _mensajeError = 'No se pudieron cargar tus reservas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}
