import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/mesa_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';
import 'package:frontend/screens/movil/reservations/reservation_schedule.dart';

class GestionMesasScreen extends StatefulWidget {
  const GestionMesasScreen({super.key});

  @override
  State<GestionMesasScreen> createState() => _GestionMesasScreenState();
}

class _GestionMesasScreenState extends State<GestionMesasScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  int? _idRestaurante;
  List<MesaAdminModel> _mesas = [];
  List<Map<String, dynamic>> _ocupacion = [];
  String _filtroEstado = 'todas';
  DateTime _fechaConsulta = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaConsulta = const TimeOfDay(hour: 14, minute: 0);
  List<WeeklyHours> _horariosSemana = [];
  List<HoursException> _excepcionesHorario = [];
  List<String> _horariosDisponibles = [];
  bool _cargandoOcupacion = false;
  String? _errorOcupacion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final urlRest = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes',
      );
      final resRest = await http.get(
        urlRest,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(
          utf8.decode(resRest.bodyBytes),
        );
        if (dataRest.isNotEmpty) {
          _idRestaurante = dataRest.first['id'];
          final urlMesas = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/mesa/restaurante/$_idRestaurante',
          );
          final urlHorarios = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/horario-atencion/restaurante/$_idRestaurante',
          );
          final urlExcepciones = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/horario-atencion/excepciones/restaurante/$_idRestaurante',
          );
          final responses = await Future.wait([
            http.get(urlMesas, headers: {'Authorization': 'Bearer $token'}),
            http.get(urlHorarios, headers: {'Authorization': 'Bearer $token'}),
            http.get(
              urlExcepciones,
              headers: {'Authorization': 'Bearer $token'},
            ),
          ]);
          final resMesas = responses[0];
          if (resMesas.statusCode == 200) {
            final List<dynamic> dataMesas = jsonDecode(
              utf8.decode(resMesas.bodyBytes),
            );
            _mesas = dataMesas.map((e) => MesaAdminModel.fromJson(e)).toList();
            _mesas.sort((a, b) => a.id.compareTo(b.id)); // o por numeroMesa
            if (responses[1].statusCode != 200 ||
                responses[2].statusCode != 200) {
              throw Exception(
                'No se pudieron cargar los horarios del restaurante.',
              );
            }
            final weeklyData =
                jsonDecode(utf8.decode(responses[1].bodyBytes))
                    as List<dynamic>;
            final exceptionData =
                jsonDecode(utf8.decode(responses[2].bodyBytes))
                    as List<dynamic>;
            _horariosSemana = [
              for (final item in weeklyData)
                WeeklyHours(
                  weekday: (item['diaSemana'] as num).toInt(),
                  start: item['horaInicio'] as String,
                  end: item['horaFin'] as String,
                ),
            ];
            _excepcionesHorario = [
              for (final item in exceptionData)
                HoursException(
                  date: item['fecha'] as String,
                  closed: item['cerrado'] as bool,
                  start: item['horaInicio'] as String?,
                  end: item['horaFin'] as String?,
                ),
            ];
            _recalcularHorariosDisponibles();
            await _consultarOcupacion(token: token);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _consultarOcupacion({String? token}) async {
    final restaurante = _idRestaurante;
    if (restaurante == null) return;
    if (_horariosDisponibles.isEmpty) {
      if (mounted) {
        setState(() {
          _ocupacion = [];
          _cargandoOcupacion = false;
          _errorOcupacion = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _cargandoOcupacion = true;
        _errorOcupacion = null;
      });
    }
    try {
      final authToken = token ?? AuthScope.of(context, listen: false).token;
      if (authToken == null) throw Exception('Inicia sesión nuevamente.');
      final fecha =
          '${_fechaConsulta.year.toString().padLeft(4, '0')}-${_fechaConsulta.month.toString().padLeft(2, '0')}-${_fechaConsulta.day.toString().padLeft(2, '0')}';
      final hora =
          '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';
      final url =
          Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$restaurante/ocupacion',
          ).replace(
            queryParameters: {
              'fecha': fecha,
              'hora': hora,
              'duracionMinutos': '60',
            },
          );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final message = body is Map ? body['message'] : null;
        throw Exception(
          message is String ? message : 'No se pudo consultar la ocupación.',
        );
      }
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['mesas'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _ocupacion = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorOcupacion = error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoOcupacion = false);
    }
  }

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

  List<Map<String, dynamic>> get _mesasFiltradas {
    return _ocupacion.where((mesa) {
      return _filtroEstado == 'todas' ||
          _estadoEnConsulta(mesa) == _filtroEstado;
    }).toList();
  }

  List<String> _slotsParaFecha(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final scheduleNow = isToday ? now : DateTime(date.year, date.month, date.day);
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
      _horariosDisponibles = _slotsParaFecha(_fechaConsulta);
      _recalcularHorariosDisponibles();
    });
    await _consultarOcupacion();
  }

  int _countForState(String state) =>
      _ocupacion.where((mesa) => _estadoEnConsulta(mesa) == state).length;

  List<DateTime> get _diasProximos {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  Future<void> _cambiarEstadoMesa(MesaAdminModel mesa) async {
    String nuevoEstado = 'libre';
    if (mesa.estado == 'libre') {
      nuevoEstado = 'ocupada';
    } else if (mesa.estado == 'ocupada') {
      nuevoEstado = 'reservada';
    } else if (mesa.estado == 'reservada') {
      nuevoEstado = 'libre';
    } else if (mesa.estado == 'inactiva') {
      return;
    }

    // Optimistic UI Update
    final originalMesas = List<MesaAdminModel>.from(_mesas);
    setState(() {
      final idx = _mesas.indexWhere((m) => m.id == mesa.id);
      if (idx != -1) {
        _mesas[idx] = MesaAdminModel(
          id: mesa.id,
          numeroMesa: mesa.numeroMesa,
          capacidad: mesa.capacidad,
          estado: nuevoEstado,
        );
      }
    });

    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/${mesa.id}');
      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Error al actualizar estado');
      }
      await _consultarOcupacion(token: token);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _mesas = originalMesas);
      if (mounted) {
        AdminNotificationModal.error(
          context,
          'No pudimos cambiar el estado de la mesa.',
        );
      }
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
    String estadoSeleccionado = mesa?.estado ?? 'libre';

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
          _guardarMesa(body, mesa?.id);
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
                  labelText: 'Estado Inicial',
                ),
                items: const [
                  DropdownMenuItem(value: 'libre', child: Text('Libre')),
                  DropdownMenuItem(value: 'ocupada', child: Text('Ocupada')),
                  DropdownMenuItem(
                    value: 'reservada',
                    child: Text('Reservada'),
                  ),
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

  Future<void> _guardarMesa(Map<String, dynamic> body, int? idMesa) async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = idMesa == null
          ? Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa')
          : Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$idMesa');

      final req = idMesa == null
          ? http.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
          : http.patch(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            );

      final res = await req;
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _cargarDatos();
        if (mounted) {
          AdminNotificationModal.success(context, 'Mesa guardada exitosamente');
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        AdminNotificationModal.error(context, 'No pudimos guardar la mesa.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMesa(int id) async {
    final conf = await AdminModal.show<bool>(
      context: context,
      title: 'Eliminar Mesa',
      confirmText: 'Eliminar',
      confirmColor: const Color(0xFFE74C3C),
      onConfirm: () => Navigator.pop(context, true),
      content: Text(
        '¿Seguro que deseas eliminar esta mesa permanentemente?',
        style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A)),
      ),
    );

    if (conf != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => _mesas.removeWhere((m) => m.id == id));
      }
    } catch (e) {
      debugPrint('Error eliminando mesa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'libre':
        return AdminTheme.success;
      case 'ocupada':
        return AdminTheme.primaryColor;
      case 'reservada':
        return AdminTheme.gold;
      case 'inactiva':
        return AdminTheme.textMuted;
      default:
        return AdminTheme.textMuted;
    }
  }

  IconData _getIconEstado(String estado) {
    switch (estado) {
      case 'libre':
        return Icons.check_circle_rounded;
      case 'ocupada':
        return Icons.remove_circle_rounded;
      case 'reservada':
        return Icons.schedule_rounded;
      default:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    int capacidadTotal = _mesas.fold(0, (sum, m) => sum + m.capacidad);
    int libres = _ocupacion.where((m) => m['disponible'] == true).length;
    int reservadas = _ocupacion
        .where((m) => _estadoEnConsulta(m) == 'reservada')
        .length;
    int ocupadas = _ocupacion
        .where((m) => _estadoEnConsulta(m) == 'ocupada')
        .length;
    int inactivas = _ocupacion
        .where((m) => _estadoEnConsulta(m) == 'inactiva')
        .length;
    final mesasFiltradas = _mesasFiltradas;
    final fechaLabel =
        '${_fechaConsulta.day.toString().padLeft(2, '0')}/${_fechaConsulta.month.toString().padLeft(2, '0')}/${_fechaConsulta.year}';
    final horaLabel = _horariosDisponibles.isEmpty
        ? 'Sin atención'
        : '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';

    final stats = [
      ('Capacidad total', '$capacidadTotal', Icons.people_alt_outlined, AdminTheme.textMuted),
      ('Libres', '$libres', Icons.chair_alt_rounded, AdminTheme.success),
      ('Ocupadas', '$ocupadas', Icons.restaurant_rounded, AdminTheme.primaryColor),
      ('Reservadas', '$reservadas', Icons.event_available_rounded, AdminTheme.gold),
      ('Inactivas', '$inactivas', Icons.block_rounded, AdminTheme.textMuted),
    ];

    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final compact = pageConstraints.maxWidth <= 640;
        final horizontalPadding = compact ? 18.0 : 34.0;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  kicker: 'SALÓN',
                  titleBefore: 'Gestión de ',
                  titleEmphasis: 'Mesas.',
                  description: 'Consulta la disponibilidad real de cada mesa por fecha y hora.',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _abrirModalMesa(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nueva mesa'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildSelector(fechaLabel, horaLabel),
                if (_errorOcupacion != null) ...[
                  const SizedBox(height: 10),
                  AdminSurface(
                    padding: const EdgeInsets.all(14),
                    radius: AdminTheme.mediumRadius,
                    child: Text('No se pudo verificar la disponibilidad: $_errorOcupacion',
                        style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.error)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 17, color: AdminTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Viendo disponibilidad de '),
                          TextSpan(text: _nombreDia(_fechaConsulta), style: const TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
                          const TextSpan(text: ' · '),
                          TextSpan(text: horaLabel, style: const TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
                        ]),
                        style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1080 ? 5 : constraints.maxWidth > 640 ? 3 : 2;
                    final gap = 12.0;
                    final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var index = 0; index < stats.length; index++)
                          SizedBox(
                            width: columns == 2 && index == 4 ? constraints.maxWidth : cardWidth,
                            child: _buildResumenCard(stats[index].$1, stats[index].$2, stats[index].$3, stats[index].$4),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AdminSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  radius: AdminTheme.pillRadius,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _buildFiltroPill('Todos', 'todas', _ocupacion.length),
                      _buildFiltroPill('Libres', 'libre', _countForState('libre')),
                      _buildFiltroPill('Ocupadas', 'ocupada', _countForState('ocupada')),
                      _buildFiltroPill('Reservadas', 'reservada', _countForState('reservada')),
                      _buildFiltroPill('Inactivas', 'inactiva', _countForState('inactiva')),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                AdminSurface(
                  padding: const EdgeInsets.all(16),
                  radius: AdminTheme.mediumRadius,
                  child: _isLoading || _cargandoOcupacion
                      ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AdminTheme.primaryColor)))
                      : _errorOcupacion != null
                          ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Text('No mostramos disponibilidad sin poder verificarla.', style: AdminTheme.bodyStyle)))
                          : _horariosDisponibles.isEmpty
                              ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Text('El restaurante no atiende en la fecha seleccionada.', style: AdminTheme.bodyStyle)))
                              : mesasFiltradas.isEmpty
                                  ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Text('No hay mesas para mostrar.', style: AdminTheme.bodyStyle)))
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: compact ? 210 : 250,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        mainAxisExtent: 238,
                                      ),
                                      itemCount: mesasFiltradas.length,
                                      itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                                        key: ValueKey('${_fechaConsulta}_${index}_${mesasFiltradas[index]['idMesa']}'),
                                        tween: Tween(begin: 0, end: 1),
                                        duration: Duration(milliseconds: 450 + index * 35),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) => Opacity(
                                          opacity: value,
                                          child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
                                        ),
                                        child: _buildMesaCard(mesasFiltradas[index]),
                                      ),
                                    ),
                ),
                const SizedBox(height: 12),
                _buildLeyenda(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelector(String fechaLabel, String horaLabel) {
    final selectedDate = DateTime(_fechaConsulta.year, _fechaConsulta.month, _fechaConsulta.day);
    final lunch = _horariosDisponibles.where((slot) => int.parse(slot.substring(0, 2)) < 17).toList();
    final dinner = _horariosDisponibles.where((slot) => int.parse(slot.substring(0, 2)) >= 17).toList();
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      radius: AdminTheme.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AdminTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_month_rounded, size: 19, color: AdminTheme.primaryColor),
            ),
            const SizedBox(width: 11),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ELIGE CUÁNDO', style: AdminTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: AdminTheme.primaryColor)),
              Text('Consulta el salón', style: AdminTheme.bodyStyle.copyWith(fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
            ]),
            const Spacer(),
            if (_cargandoOcupacion)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(tooltip: 'Actualizar disponibilidad', onPressed: _consultarOcupacion, icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 14),
          _selectorLabel('DÍA', 'Próximos días'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final day in _diasProximos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildDayChip(day, selectedDate),
                ),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: AdminTheme.border)),
          _selectorLabel('HORA', 'Horario de atención · 1 hora por reserva'),
          const SizedBox(height: 9),
          if (_horariosDisponibles.isEmpty)
            Text('Sin horarios disponibles para este día.', style: AdminTheme.bodyStyle.copyWith(fontSize: 12))
          else ...[
            if (lunch.isNotEmpty) _buildHourGroup('ALMUERZO', lunch, horaLabel),
            if (lunch.isNotEmpty && dinner.isNotEmpty) const SizedBox(height: 9),
            if (dinner.isNotEmpty) _buildHourGroup('CENA', dinner, horaLabel),
          ],
          const SizedBox(height: 9),
          Wrap(spacing: 14, runSpacing: 6, children: [
            _buildDotLegend(const Color(0xFFC4B7A3), 'Sin reservas'),
            _buildDotLegend(AdminTheme.gold, 'Con reservas'),
            _buildDotLegend(AdminTheme.error, 'Ocupada'),
          ]),
          const SizedBox(height: 7),
          Text('$fechaLabel · Los indicadores reflejan la consulta seleccionada.', style: AdminTheme.bodyStyle.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _selectorLabel(String label, String value) => Row(children: [
        SizedBox(width: 54, child: Text(label, style: AdminTheme.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AdminTheme.textMuted))),
        Text(value, style: AdminTheme.bodyStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.textDark)),
      ]);

  Widget _buildDayChip(DateTime date, DateTime selectedDate) {
    final slots = _slotsParaFecha(date);
    final isOpen = _tieneAtencionConfigurada(date);
    final canSelect = slots.isNotEmpty;
    final active = date == selectedDate;
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final labels = const ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return Tooltip(
      message: !isOpen ? 'Cerrado' : canSelect ? _nombreDia(date) : 'Atención finalizada por hoy',
      child: InkWell(
        onTap: !canSelect || _cargandoOcupacion ? null : () => _seleccionarDia(date),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AdminTheme.primaryColor : isOpen ? AdminTheme.surface : AdminTheme.background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? AdminTheme.primaryColor : AdminTheme.border, width: 1.4),
            boxShadow: active ? [const BoxShadow(color: Color(0x4DBE4B24), blurRadius: 12, offset: Offset(0, 4))] : null,
          ),
          child: Opacity(
            opacity: isOpen ? 1 : .5,
            child: Column(children: [
              Text(isToday ? 'HOY' : labels[date.weekday - 1], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8, color: active ? Colors.white : AdminTheme.textMuted)),
              const SizedBox(height: 1),
              Text('${date.day}', style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w600, height: 1.1, color: active ? Colors.white : AdminTheme.textDark, decoration: isOpen ? null : TextDecoration.lineThrough, decorationColor: AdminTheme.error)),
              Text(!isOpen ? 'Cerrado' : !canSelect ? 'Finalizado' : (active ? 'ABIERTO' : 'Abierto'), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: active ? Colors.white70 : AdminTheme.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHourGroup(String label, List<String> slots, String horaLabel) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: AdminTheme.background, borderRadius: AdminTheme.pillRadius, border: Border.all(color: AdminTheme.border)), child: Text(label, style: AdminTheme.bodyStyle.copyWith(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .5))),
          for (final slot in slots) _buildHourChip(slot, slot == horaLabel),
        ],
      );

  Widget _buildHourChip(String slot, bool active) {
    final hasReservations = _ocupacion.any((mesa) => mesa['reserva'] != null);
    final isOccupied = _ocupacion.any((mesa) => _estadoEnConsulta(mesa) == 'ocupada');
    final dotColor = active ? (isOccupied ? AdminTheme.error : hasReservations ? AdminTheme.gold : const Color(0xFFC4B7A3)) : const Color(0xFFC4B7A3);
    return InkWell(
      onTap: _cargandoOcupacion ? null : () {
        final parts = slot.split(':').map(int.parse).toList();
        setState(() => _horaConsulta = TimeOfDay(hour: parts[0], minute: parts[1]));
        _consultarOcupacion();
      },
      borderRadius: AdminTheme.pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: active ? AdminTheme.primaryColor : AdminTheme.surface, borderRadius: AdminTheme.pillRadius, border: Border.all(color: active ? AdminTheme.primaryColor : AdminTheme.border), boxShadow: active ? [const BoxShadow(color: Color(0x3DBE4B24), blurRadius: 10, offset: Offset(0, 3))] : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: active ? Colors.white : dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(slot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AdminTheme.textDark)),
        ]),
      ),
    );
  }

  Widget _buildDotLegend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AdminTheme.bodyStyle.copyWith(fontSize: 10)),
      ]);

  String _nombreDia(DateTime date) {
    const names = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return '${names[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildResumenCard(String titulo, String valor, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: AdminTheme.mediumRadius, border: Border.all(color: AdminTheme.border), boxShadow: AdminTheme.shadowSm),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: AdminTheme.titleStyle.copyWith(fontSize: 24)),
          Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildFiltroPill(String label, String valor, int count) {
    final active = _filtroEstado == valor;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = valor),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primaryColor : AdminTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? AdminTheme.primaryColor : AdminTheme.border,
          ),
          boxShadow: active ? AdminTheme.shadowSm : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(valor == 'todas' ? Icons.table_restaurant_outlined : _getIconEstado(valor), size: 14, color: active ? Colors.white : AdminTheme.textMuted),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : AdminTheme.textMuted)),
          const SizedBox(width: 7),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: active ? Colors.white24 : AdminTheme.background, borderRadius: AdminTheme.pillRadius), child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: active ? Colors.white : AdminTheme.textMuted))),
        ]),
      ),
    );
  }

  Widget _buildLeyenda() => AdminSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        radius: AdminTheme.mediumRadius,
        child: Wrap(spacing: 20, runSpacing: 10, children: [
          _buildStatusLegend(AdminTheme.success, 'Libre', 'disponible para reservar'),
          _buildStatusLegend(AdminTheme.primaryColor, 'Ocupada', 'comensales en mesa'),
          _buildStatusLegend(AdminTheme.gold, 'Reservada', 'con reserva asignada'),
          _buildStatusLegend(AdminTheme.textMuted, 'Inactiva', 'fuera de servicio'),
        ]),
      );

  Widget _buildStatusLegend(Color color, String state, String detail) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 7),
        Text('$state — $detail', style: AdminTheme.bodyStyle.copyWith(fontSize: 11)),
      ]);

  Widget _buildMesaCard(Map<String, dynamic> datosMesa) {
    final idMesa = (datosMesa['idMesa'] as num).toInt();
    final mesaGuardada = _mesas.firstWhere((item) => item.id == idMesa);
    final estado = _estadoEnConsulta(datosMesa);
    final mesa = MesaAdminModel(
      id: mesaGuardada.id,
      numeroMesa: mesaGuardada.numeroMesa,
      capacidad: mesaGuardada.capacidad,
      estado: estado,
    );
    final reserva = datosMesa['reserva'] as Map<String, dynamic>?;
    final horaReserva = reserva?['hora']?.toString() ?? '';
    final color = _getColorEstado(estado);
    final icon = _getIconEstado(estado);

    final stateLabel = switch (estado) {
      'libre' => 'Libre',
      'ocupada' => 'Ocupada',
      'reservada' => 'Reservada',
      _ => 'Inactiva',
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: AdminTheme.mediumRadius, boxShadow: AdminTheme.shadowSm, border: Border.all(color: AdminTheme.border)),
      child: ClipRRect(
        borderRadius: AdminTheme.mediumRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: reserva != null || estado == 'inactiva' ? null : () => _cambiarEstadoMesa(mesa),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(height: 4, color: color),
              Expanded(
                child: Opacity(
                  opacity: estado == 'inactiva' ? .55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 9, 15, 13),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('MESA', style: AdminTheme.bodyStyle.copyWith(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                          Text(mesa.numeroMesa, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.fraunces(fontSize: 25, fontWeight: FontWeight.w600, height: 1.1, color: AdminTheme.textDark, decoration: estado == 'inactiva' ? TextDecoration.lineThrough : null, decorationThickness: 2)),
                        ])),
                        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.chair_alt_rounded, color: color, size: 20)),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                          icon: const Icon(Icons.more_horiz_rounded, color: AdminTheme.textMuted, size: 20),
                          onSelected: (val) { if (val == 'edit') _abrirModalMesa(mesa: mesa); if (val == 'delete') _eliminarMesa(mesa.id); },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Editar')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AdminTheme.error), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: AdminTheme.error))])),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 11),
                      Wrap(spacing: 7, runSpacing: 7, children: [
                        _buildSmallChip(Icons.people_alt_outlined, '${mesa.capacidad} personas', AdminTheme.textMuted, AdminTheme.background),
                        _buildSmallChip(icon, stateLabel, color, color.withValues(alpha: .11)),
                      ]),
                      if (reserva != null) ...[
                        const SizedBox(height: 10),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.person_outline_rounded, size: 15, color: AdminTheme.textMuted),
                          const SizedBox(width: 5),
                          Expanded(child: Text('${reserva['cliente']?.toString().isNotEmpty == true ? reserva['cliente'] : 'Cliente'} · ${horaReserva.length >= 5 ? horaReserva.substring(0, 5) : horaReserva}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 11, color: AdminTheme.textDark))),
                        ]),
                      ] else if (estado != 'libre') ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(estado == 'inactiva' ? Icons.block_outlined : Icons.schedule_rounded, size: 14, color: AdminTheme.textMuted),
                          const SizedBox(width: 5),
                          Expanded(child: Text(estado == 'inactiva' ? 'Fuera de servicio' : 'Comensales en mesa', maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 11))),
                        ]),
                      ],
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallChip(IconData icon, String label, Color foreground, Color background) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: AdminTheme.pillRadius),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: foreground)),
        ]),
      );
}
