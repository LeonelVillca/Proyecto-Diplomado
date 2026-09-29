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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _apiError(dynamic response, String fallback) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'];
      if (message is List) return message.join(', ');
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return fallback;
  }

  void _showError(String message) {
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

  Future<void> _loadOptions() async {
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
          _apiError(responses[0], 'No se pudieron cargar los horarios.'),
        );
      }
      if (responses[1].statusCode != 200) {
        throw Exception(
          _apiError(responses[1], 'No se pudieron cargar los días especiales.'),
        );
      }
      if (responses[2].statusCode != 200) {
        throw Exception(
          _apiError(responses[2], 'No se pudieron cargar las mesas.'),
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
      _refreshSlotAvailability();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<List<dynamic>> _availableTables({
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
        _apiError(response, 'No se pudo consultar la disponibilidad.'),
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body['mesas'] as List<dynamic>;
  }

  Future<void> _checkAvailability() async {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return;
    final version = ++_requestVersion;
    final guests = _guests;
    final token = AuthScope.of(context, listen: false).token;
    if (token == null) {
      _showError('Inicia sesión para consultar la disponibilidad.');
      return;
    }
    setState(() {
      _checkingAvailability = true;
      _availableCount = null;
      _errorMessage = null;
    });
    try {
      final tables = await _availableTables(
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
        _showError(
          'No hay mesas disponibles para $guests personas en ese horario. Elige otra hora o fecha.',
        );
      }
    } catch (error) {
      if (mounted && version == _requestVersion) _showError(error.toString());
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _checkingAvailability = false);
      }
    }
  }

  Future<void> _refreshSlotAvailability() async {
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
          _availableTables(
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

  Future<void> _submit() async {
    if (_submitting) return;
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) {
      _showError('Selecciona una fecha y una hora para continuar.');
      return;
    }
    final guests = _guests;
    final auth = AuthScope.of(context, listen: false);
    final userId = auth.idUsuario;
    final token = auth.token;
    if (userId == null || token == null) {
      _showError('Inicia sesión para solicitar una reserva.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      // La comprobación se repite aunque ya se haya mostrado una vista previa.
      final tables = await _availableTables(
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
        throw Exception(_apiError(response, 'No se pudo crear la reserva.'));
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ReservationSentScreen(
            restaurant: widget.restaurant,
            date: _longDate(date),
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
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _longDate(DateTime date) {
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
    return '${date.day} de ${months[date.month - 1]}';
  }

  String _shortMonth(DateTime date) {
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
    return months[date.month - 1];
  }

  String _shortDay(DateTime date) {
    const weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return weekdays[date.weekday - 1];
  }

  String _dayHeading(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return 'HOY';
    return _shortDay(date).toUpperCase();
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ConsumerColors.card,
                    border: Border.all(color: ConsumerColors.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: widget.restaurant.photoUrl == null
                              ? const ColoredBox(
                                  color: ConsumerColors.paperDeep,
                                  child: Icon(
                                    Icons.restaurant,
                                    color: ConsumerColors.wine,
                                  ),
                                )
                              : Image.network(
                                  widget.restaurant.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: ConsumerColors.paperDeep,
                                    child: Icon(
                                      Icons.restaurant,
                                      color: ConsumerColors.wine,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: ConsumerColors.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.restaurant.rating.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.restaurant.cuisineLabel +
                                        ' · ' +
                                        widget.restaurant.zone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '¿Cuándo?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      'Próximos 7 días',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loadingOptions)
                  const SizedBox(
                    height: 84,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ConsumerColors.wine,
                      ),
                    ),
                  )
                else if (_days.isEmpty)
                  Text(
                    _errorMessage == null
                        ? 'No hay fechas reservables durante los próximos días.'
                        : 'No se pudieron consultar las fechas disponibles.',
                  )
                else
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final date = _days[index].date;
                        final selected =
                            _selectedDate != null &&
                            reservationDateKey(date) ==
                                reservationDateKey(_selectedDate!);
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: _dayHeading(date) + ', ' + _longDate(date),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDate = date;
                                      _selectedTime = null;
                                      _availableCount = null;
                                      _unavailableSlots.clear();
                                      _checkingAvailability = false;
                                      _errorMessage = null;
                                      _requestVersion++;
                                    });
                                    _refreshSlotAvailability();
                                  },
                            child: Container(
                              width: 62,
                              decoration: BoxDecoration(
                                color: selected
                                    ? ConsumerColors.wine
                                    : ConsumerColors.card,
                                border: Border.all(
                                  color: selected
                                      ? ConsumerColors.wine
                                      : ConsumerColors.line,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _dayHeading(date),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : ConsumerColors.inkSoft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontFamily: 'Fraunces',
                                      color: selected
                                          ? Colors.white
                                          : ConsumerColors.ink,
                                      fontSize: 24,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _shortMonth(date),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : ConsumerColors.inkSoft,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '¿A qué hora?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      'Horario local',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Dura 1 hora; la mesa se bloquea 30 min antes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (slots.isEmpty)
                  Text(
                    'No hay horarios disponibles para este día.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: slots.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 2.3,
                        ),
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final selected = _selectedTime == slot;
                      final unavailable = _unavailableSlots.contains(slot);
                      return Semantics(
                        button: !unavailable,
                        enabled: !unavailable,
                        selected: selected,
                        label: unavailable ? slot + ', completo' : slot,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap:
                              _submitting ||
                                  _checkingAvailability ||
                                  unavailable
                              ? null
                              : () {
                                  setState(() {
                                    _selectedTime = slot;
                                    _availableCount = null;
                                  });
                                  _checkAvailability();
                                },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? ConsumerColors.wine
                                  : ConsumerColors.card,
                              border: Border.all(
                                color: selected
                                    ? ConsumerColors.wine
                                    : ConsumerColors.line,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _checkingAvailability && selected
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    slot,
                                    style: TextStyle(
                                      color: unavailable
                                          ? ConsumerColors.inkSoft
                                          : selected
                                          ? Colors.white
                                          : ConsumerColors.ink,
                                      decoration: unavailable
                                          ? TextDecoration.lineThrough
                                          : null,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                if (_checkingAvailability) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Comprobando disponibilidad…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else if (_availableCount != null && _availableCount! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _availableCount.toString() +
                        ' mesas disponibles para este horario.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: ConsumerColors.sage),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '¿Cuántos son?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      'Máx. ' + _maxGuests.toString() + ' personas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ConsumerColors.card,
                    border: Border.all(color: ConsumerColors.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.outlined(
                        tooltip: 'Una persona menos',
                        onPressed: _submitting || _guests <= 1
                            ? null
                            : () {
                                setState(() {
                                  _guests--;
                                  _unavailableSlots.clear();
                                });
                                _refreshSlotAvailability();
                              },
                        icon: const Icon(LucideIcons.minus),
                      ),
                      SizedBox(
                        width: 96,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _guests.toString(),
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: ConsumerColors.ink,
                              ),
                            ),
                            Text(
                              _guests == 1 ? 'persona' : 'personas',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Una persona más',
                        onPressed: _submitting || _guests >= _maxGuests
                            ? null
                            : () {
                                setState(() {
                                  _guests++;
                                  _unavailableSlots.clear();
                                });
                                _refreshSlotAvailability();
                              },
                        icon: const Icon(LucideIcons.plus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Peticiones especiales',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Opcional. Cuéntale al restaurante si necesitas algo para tu visita.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  enabled: !_submitting,
                  maxLines: 3,
                  maxLength: 255,
                  decoration: InputDecoration(
                    hintText: 'Por ejemplo, una silla para bebé o una alergia',
                    filled: true,
                    fillColor: ConsumerColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ConsumerColors.paper,
          border: Border(top: BorderSide(color: ConsumerColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TU RESERVA',
                        style: TextStyle(
                          color: ConsumerColors.inkSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
                        ),
                      ),
                      Text(
                        _selectedDate == null || _selectedTime == null
                            ? 'Elige día y hora'
                            : _selectedDate!.day.toString() +
                                  ' ' +
                                  _shortMonth(_selectedDate!) +
                                  ' · ' +
                                  _selectedTime! +
                                  ' · ' +
                                  _guests.toString() +
                                  (_guests == 1 ? ' persona' : ' personas'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ConsumerColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selectedTime != null)
                        Text(
                          'Duración: 1 hora',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
