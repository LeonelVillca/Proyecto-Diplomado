import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/reserva_admin_model.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

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
  String? _socketToken;
  String _filtroEstado = 'todas';
  bool _historial = false;
  int _pagina = 1;
  int? _confirmando;
  final _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AuthScope.of(context);
    if (_idRestaurante != null) _conectarSocket();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
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
      debugPrint('Websocket conectado para reservas');
    });

    _socket!.on('nueva_reserva', (data) {
      if (data['idRestaurante'] == _idRestaurante) {
        if (mounted) {
          AdminNotificationModal.success(context, '¡Nueva reserva entrante!');
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
    if (_isLoading) return;
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

  // Estado exclusivamente visual: no modifica reservas ni consultas.
  DateTime _dia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);
  String _hora(DateTime fecha) =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  TextStyle _texto({
    double size = 13,
    Color color = AdminTheme.textMuted,
    bool bold = false,
  }) => TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: size,
    color: color,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
  );
  Color _color(String estado) => switch (estado) {
    'confirmada' => AdminTheme.success,
    'pendiente' => AdminTheme.warning,
    'finalizada' => AdminTheme.accentColor,
    _ => AdminTheme.error,
  };
  Color _fondo(String estado) => switch (estado) {
    'confirmada' => AdminTheme.successSoft,
    'pendiente' => AdminTheme.warningSoft,
    'finalizada' => AdminTheme.accentSoft,
    _ => AdminTheme.errorSoft,
  };
  IconData _icono(String estado) => switch (estado) {
    'confirmada' => LucideIcons.checkCheck,
    'pendiente' => LucideIcons.hourglass,
    'finalizada' => LucideIcons.check,
    _ => LucideIcons.x,
  };
  String _nombreEstado(String estado) => switch (estado) {
    'confirmada' => 'Confirmada',
    'pendiente' => 'Pendiente',
    'finalizada' => 'Completada',
    'rechazada' => 'Rechazada',
    'cancelada' => 'Cancelada',
    _ => estado,
  };
  Widget _chip(String texto, IconData icono, Color fondo, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: AdminTheme.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: _texto(size: 12, color: color, bold: true),
              ),
            ),
          ],
        ),
      );
  Widget _selector(
    String label,
    IconData icon,
    int count,
    bool active,
    VoidCallback onTap,
  ) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: active ? AdminTheme.primaryColor : Colors.transparent,
      foregroundColor: active ? Colors.white : AdminTheme.textMuted,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      shape: const StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 7),
        Text(
          label,
          style: _texto(
            color: active ? Colors.white : AdminTheme.textMuted,
            bold: true,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: .22)
                : const Color(0xFFEFE7DA),
            borderRadius: AdminTheme.pillRadius,
          ),
          child: Text(
            '$count',
            style: _texto(
              size: 11,
              color: active ? Colors.white : AdminTheme.textMuted,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _barra(List<Widget> children) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AdminTheme.border),
      borderRadius: AdminTheme.pillRadius,
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    ),
  );
  Widget _stat(
    String label,
    String value,
    IconData icon,
    Color color,
    Color background, {
    int? count,
    bool pulse = false,
  }) => _ReservaHover(
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (count != null)
                TweenAnimationBuilder<double>(
                  key: ValueKey('$label$count'),
                  tween: Tween(begin: 0, end: count.toDouble()),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => Text(
                    '${value.round()}',
                    style: AdminTheme.titleStyle.copyWith(fontSize: 25),
                  ),
                )
              else
                Text(
                  value,
                  style: AdminTheme.titleStyle.copyWith(fontSize: 19),
                ),
              const SizedBox(height: 4),
              Text(label, style: _texto(size: 12, bold: true)),
            ],
          ),
        ),
        if (pulse) const _PendientePulse(),
      ],
    ),
  );
  Future<void> _confirmarConFeedback(ReservaAdminModel reserva) async {
    setState(() => _confirmando = reserva.id);
    try {
      await _cambiarEstadoReserva(reserva, 'confirmada');
      if (!mounted) return;
      if (_reservas.any(
        (r) => r.id == reserva.id && r.estado == 'confirmada',
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 3200),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AdminTheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: TweenAnimationBuilder<double>(
              tween: Tween(begin: 16, end: 0),
              duration: const Duration(milliseconds: 450),
              curve: const Cubic(.2, .9, .3, 1.2),
              builder: (_, offset, child) =>
                  Transform.translate(offset: Offset(0, offset), child: child),
              child: Text(
                'Reserva confirmada',
                style: _texto(color: Colors.white),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmando = null);
    }
  }

  Widget _acciones(ReservaAdminModel reserva) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (reserva.estado == 'pendiente') ...[
        FilledButton.icon(
          onPressed: _isLoading ? null : () => _confirmarConFeedback(reserva),
          style: FilledButton.styleFrom(
            backgroundColor: AdminTheme.primaryColor,
            shape: const StadiumBorder(),
          ),
          icon: _confirmando == reserva.id
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.check, size: 13),
          label: Text(
            _confirmando == reserva.id ? 'Confirmando…' : 'Confirmar',
            style: _texto(size: 12, color: Colors.white, bold: true),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () => _cambiarEstadoReserva(reserva, 'rechazada'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminTheme.error,
            side: const BorderSide(color: Color(0xFFF0CFC5)),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(LucideIcons.x, size: 13),
          label: Text(
            'Rechazar',
            style: _texto(size: 12, color: AdminTheme.error, bold: true),
          ),
        ),
      ],
    ],
  );
  Widget _reserva(
    ReservaAdminModel reserva,
    int index,
    bool last,
    bool mobile,
  ) {
    final dot = switch (reserva.estado) {
      'confirmada' => const Color(0xFF5FA97F),
      'pendiente' => AdminTheme.gold,
      'finalizada' => AdminTheme.accentColor,
      _ => const Color(0xFFD8CDBC),
    };
    const avatars = [
      AdminTheme.primaryColor,
      AdminTheme.accentColor,
      AdminTheme.gold,
      Color(0xFF4B4B8F),
      Color(0xFF2E7D6B),
    ];
    final mesa = reserva.numeroMesa;
    final card = Opacity(
      opacity: reserva.estado == 'cancelada' || reserva.estado == 'rechazada'
          ? .72
          : 1,
      child: _ReservaHover(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatars[index % avatars.length],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'R${reserva.id}',
                    style: AdminTheme.titleStyle.copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserva #${reserva.id}',
                        style: _texto(
                          size: 16,
                          color: AdminTheme.textDark,
                          bold: true,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.users,
                                size: 13,
                                color: AdminTheme.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${reserva.cantidadPersonas} ${reserva.cantidadPersonas == 1 ? 'persona' : 'personas'}',
                                style: _texto(size: 12),
                              ),
                            ],
                          ),
                          CustomPaint(
                            foregroundPainter:
                                mesa == null && reserva.idMesa == 0
                                ? const _ReservaDashedBorder(
                                    radius: 999,
                                    color: Color(0xFFE3C88A),
                                  )
                                : null,
                            child: _chip(
                              mesa != null
                                  ? 'Mesa $mesa'
                                  : reserva.idMesa != 0
                                  ? 'Mesa · ID ${reserva.idMesa}'
                                  : 'Sin asignar',
                              mesa != null || reserva.idMesa != 0
                                  ? LucideIcons.armchair
                                  : LucideIcons.circleAlert,
                              mesa == null && reserva.idMesa == 0
                                  ? AdminTheme.background
                                  : AdminTheme.primaryLight,
                              mesa == null && reserva.idMesa == 0
                                  ? AdminTheme.warning
                                  : AdminTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reserva.requerimientosEspeciales?.trim().isNotEmpty ??
                false) ...[
              const SizedBox(height: 10),
              _chip(
                reserva.requerimientosEspeciales!,
                LucideIcons.messageCircle,
                AdminTheme.primaryLight,
                AdminTheme.primaryDark,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(
                  _nombreEstado(reserva.estado),
                  _icono(reserva.estado),
                  _fondo(reserva.estado),
                  _color(reserva.estado),
                ),
                if (!mobile) _acciones(reserva),
              ],
            ),
            if (mobile && reserva.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              _acciones(reserva),
            ],
          ],
        ),
      ),
    );
    return TweenAnimationBuilder<double>(
      key: ValueKey('${reserva.id}-$_pagina-$_historial-$_filtroEstado'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 60),
      curve: Interval(index * 60 / (500 + index * 60), 1, curve: Curves.ease),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(16 * (1 - value), 0),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: mobile ? 58 : 76,
              child: Padding(
                padding: const EdgeInsets.only(top: 24, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hora(reserva.fechaHora),
                      style: AdminTheme.titleStyle.copyWith(
                        fontSize: mobile ? 16 : 18.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reserva.estado == 'pendiente'
                          ? 'POR\nCONFIRMAR'
                          : 'LLEGADA',
                      textAlign: TextAlign.right,
                      style: _texto(size: 10, bold: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: mobile ? 20 : 24,
              child: Column(
                children: [
                  const SizedBox(height: 27),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AdminTheme.background,
                        width: 3,
                      ),
                      boxShadow: [BoxShadow(color: dot, spreadRadius: 2)],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: last ? Colors.transparent : AdminTheme.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 7, 0, 7),
                child: card,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diaHeader(DateTime day, List<ReservaAdminModel> reservas) {
    final today = _dia(DateTime.now());
    final delta = day.difference(today).inDays;
    final tag = delta == 0
        ? 'HOY'
        : delta == 1
        ? 'MAÑANA'
        : delta > 1
        ? '+$delta DÍAS'
        : delta == -1
        ? 'AYER'
        : 'PASADO';
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: delta == 0
                  ? AdminTheme.primaryColor
                  : delta > 0
                  ? AdminTheme.primaryLight
                  : AdminTheme.rowBorder,
              borderRadius: AdminTheme.pillRadius,
            ),
            child: Text(
              tag,
              style: _texto(
                size: 11,
                color: delta == 0
                    ? Colors.white
                    : delta > 0
                    ? AdminTheme.primaryDark
                    : AdminTheme.textMuted,
                bold: true,
              ),
            ),
          ),
          Text(
            '${day.day} de ${months[day.month - 1]} de ${day.year}',
            style: AdminTheme.titleStyle.copyWith(fontSize: 17),
          ),
          Text(
            '${reservas.length} reservas · ${reservas.fold<int>(0, (sum, r) => sum + r.cantidadPersonas)} personas',
            style: _texto(size: 12),
          ),
        ],
      ),
    );
  }

  void _irPagina(int pagina) {
    setState(() => _pagina = pagina);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dia(now);
    final proximas = _reservas
        .where((r) => !_dia(r.fechaHora).isBefore(today))
        .toList();
    final historial = _reservas
        .where((r) => _dia(r.fechaHora).isBefore(today))
        .toList();
    final vista = _historial ? historial : proximas;
    final filtradas =
        vista
            .where((r) => _filtroEstado == 'todas' || r.estado == _filtroEstado)
            .toList()
          ..sort((a, b) {
            final days = _dia(a.fechaHora).compareTo(_dia(b.fechaHora));
            return days == 0
                ? a.fechaHora.compareTo(b.fechaHora)
                : _historial
                ? -days
                : days;
          });
    final paginas = (filtradas.length / 8).ceil();
    final pagina = _pagina.clamp(1, paginas == 0 ? 1 : paginas);
    final start = (pagina - 1) * 8;
    final actuales = filtradas.skip(start).take(8).toList();
    final groups = <DateTime, List<ReservaAdminModel>>{};
    for (final reserva in actuales) {
      groups.putIfAbsent(_dia(reserva.fechaHora), () => []).add(reserva);
    }
    final pendientes = _reservas.where((r) => r.estado == 'pendiente').length;
    final hoy = _reservas
        .where((r) => _dia(r.fechaHora) == today && r.estado == 'confirmada')
        .toList();
    final llegadas = hoy.where((r) => !r.fechaHora.isBefore(now)).toList()
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    final siguiente = llegadas.isEmpty ? null : llegadas.first;
    final estados = <(String, String)>[
      ('Todas', 'todas'),
      ('Pendientes', 'pendiente'),
      ('Confirmadas', 'confirmada'),
      ('Completadas', 'finalizada'),
      ('Canceladas', 'cancelada'),
      ('Rechazadas', 'rechazada'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth <= 640;
        final columns = constraints.maxWidth <= 1080 ? 2 : 4;
        return ColoredBox(
          color: AdminTheme.background,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 34,
              28,
              mobile ? 16 : 34,
              70,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 932),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdminPageHeader(
                      kicker: 'SERVICIO',
                      titleBefore: 'Gestión de ',
                      titleEmphasis: 'Reservas.',
                      description:
                          'Todas las reservas de tu restaurante, separadas entre próximas y pasadas.',
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (_, size) {
                        final n = siguiente == null && columns == 4
                            ? 3
                            : columns;
                        final width = (size.maxWidth - 12 * (n - 1)) / n;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              child: _stat(
                                'Nuevas pendientes',
                                '$pendientes',
                                LucideIcons.bellRing,
                                AdminTheme.warning,
                                AdminTheme.warningSoft,
                                count: pendientes,
                                pulse: pendientes > 0,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _stat(
                                'Confirmadas de hoy',
                                '${hoy.length}',
                                LucideIcons.checkCheck,
                                AdminTheme.success,
                                AdminTheme.successSoft,
                                count: hoy.length,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _stat(
                                'Personas esperadas hoy',
                                '',
                                LucideIcons.users,
                                AdminTheme.accentColor,
                                AdminTheme.accentSoft,
                                count: hoy.fold<int>(
                                  0,
                                  (sum, r) => sum + r.cantidadPersonas,
                                ),
                              ),
                            ),
                            if (siguiente != null)
                              SizedBox(
                                width: width,
                                child: _stat(
                                  'Próxima llegada${siguiente.numeroMesa == null ? '' : ' · Mesa ${siguiente.numeroMesa}'}',
                                  _hora(siguiente.fechaHora),
                                  LucideIcons.clock,
                                  AdminTheme.primaryColor,
                                  AdminTheme.primaryLight,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _barra([
                        _selector(
                          'Próximas',
                          LucideIcons.calendarClock,
                          proximas.length,
                          !_historial,
                          () => setState(() {
                            _historial = false;
                            _pagina = 1;
                          }),
                        ),
                        _selector(
                          'Historial',
                          LucideIcons.history,
                          historial.length,
                          _historial,
                          () => setState(() {
                            _historial = true;
                            _pagina = 1;
                          }),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _barra([
                        for (final (label, estado) in estados)
                          _selector(
                            label,
                            estado == 'todas'
                                ? LucideIcons.layoutGrid
                                : _icono(estado),
                            estado == 'todas'
                                ? vista.length
                                : vista.where((r) => r.estado == estado).length,
                            _filtroEstado == estado,
                            () => setState(() {
                              _filtroEstado = estado;
                              _pagina = 1;
                            }),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading && _reservas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(56),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      )
                    else if (actuales.isEmpty)
                      CustomPaint(
                        foregroundPainter: const _ReservaDashedBorder(
                          radius: 22,
                          color: Color(0xFFD5C9B8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 56,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.calendarX,
                                size: 38,
                                color: AdminTheme.primaryColor,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Sin reservas por aquí',
                                style: AdminTheme.titleStyle.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay reservas para esta vista y estado.',
                                style: _texto(),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final entry in groups.entries) ...[
                        _diaHeader(entry.key, entry.value),
                        for (var i = 0; i < entry.value.length; i++)
                          _reserva(
                            entry.value[i],
                            actuales.indexOf(entry.value[i]),
                            i == entry.value.length - 1,
                            mobile,
                          ),
                      ],
                    if (filtradas.length > 8)
                      Container(
                        margin: const EdgeInsets.only(top: 18),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AdminTheme.mediumRadius,
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Mostrando ${start + 1} – ${start + actuales.length} de ${filtradas.length} reservas',
                              style: _texto(),
                            ),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                _paginaBoton(
                                  null,
                                  LucideIcons.chevronLeft,
                                  false,
                                  pagina > 1
                                      ? () => _irPagina(pagina - 1)
                                      : null,
                                ),
                                for (var p = 1; p <= paginas; p++)
                                  _paginaBoton(
                                    '$p',
                                    null,
                                    p == pagina,
                                    () => _irPagina(p),
                                  ),
                                _paginaBoton(
                                  null,
                                  LucideIcons.chevronRight,
                                  false,
                                  pagina < paginas
                                      ? () => _irPagina(pagina + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paginaBoton(
    String? label,
    IconData? icon,
    bool active,
    VoidCallback? onTap,
  ) => SizedBox(
    width: 36,
    height: 36,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: active ? Colors.white : AdminTheme.textMuted,
        backgroundColor: active ? AdminTheme.primaryColor : Colors.white,
        side: BorderSide(
          color: active ? AdminTheme.primaryColor : AdminTheme.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: icon == null
          ? Text(label!, style: const TextStyle(fontWeight: FontWeight.w700))
          : Icon(icon, size: 16),
    ),
  );
}

class _ReservaHover extends StatefulWidget {
  const _ReservaHover({
    required this.child,
    required this.radius,
    required this.padding,
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  @override
  State<_ReservaHover> createState() => _ReservaHoverState();
}

class _ReservaHoverState extends State<_ReservaHover> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _hover ? const Color(0xFFD8CDBC) : AdminTheme.border,
        ),
        boxShadow: _hover ? AdminTheme.shadowMd : [],
      ),
      child: widget.child,
    ),
  );
}

class _PendientePulse extends StatefulWidget {
  const _PendientePulse();
  @override
  State<_PendientePulse> createState() => _PendientePulseState();
}

class _PendientePulseState extends State<_PendientePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, _) => SizedBox(
      width: 17,
      height: 17,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: .6 + .9 * _animation.value,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdminTheme.gold.withValues(
                  alpha: .4 * (1 - _animation.value),
                ),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AdminTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReservaDashedBorder extends CustomPainter {
  const _ReservaDashedBorder({required this.radius, required this.color});
  final double radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 10) {
        canvas.drawPath(
          metric.extractPath(offset, (offset + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ReservaDashedBorder oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
