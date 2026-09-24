import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/screens/movil/reservations/reservation_schedule.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  static const int _durationMinutes = 120;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<ReservationDay> _days = [];
  DateTime? _selectedDate;
  String? _selectedTime;
  int _guests = 2;
  int _maxGuests = 0;
  int? _availableCount;
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
        _days = dates;
        _selectedDate = dates.isEmpty ? null : dates.first.date;
        _selectedTime = null;
        _maxGuests = maximum > 8 ? 8 : maximum;
        if (_maxGuests > 0 && _guests > _maxGuests) _guests = _maxGuests;
        _availableCount = null;
        _requestVersion++;
      });
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
      setState(() => _availableCount = tables.length);
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
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Solicitud enviada'),
          content: Text(
            'Tu reserva en ${widget.restaurant.name} para el ${_longDate(date)} a las $time '
            'por $guests personas quedó pendiente de confirmación.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final selectedDay = [
      for (final day in _days)
        if (_selectedDate != null &&
            reservationDateKey(day.date) == reservationDateKey(_selectedDate!))
          day,
    ];
    final slots = selectedDay.isEmpty ? <String>[] : selectedDay.first.slots;
    final titleStyle = GoogleFonts.piazzolla(
      color: AppColors.ink,
      fontSize: 21,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        title: Text(
          'Reservar mesa',
          style: GoogleFonts.piazzolla(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  InlineErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  widget.restaurant.name,
                  style: GoogleFonts.piazzolla(
                    color: AppColors.wine,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige cuántas personas vendrán, un día de atención y una hora. '
                  'La solicitud quedará pendiente hasta que el restaurante la confirme.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 30),
                Text('¿Cuántas personas?', style: titleStyle),
                const SizedBox(height: 6),
                Text(
                  'Mostramos mesas con capacidad suficiente para tu grupo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_loadingOptions)
                  const LinearProgressIndicator()
                else if (_maxGuests == 0)
                  const Text(
                    'Este restaurante no tiene mesas activas disponibles.',
                  )
                else
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (var number = 1; number <= _maxGuests; number++)
                        ChoiceChip(
                          label: Text('$number'),
                          selected: _guests == number,
                          selectedColor: AppColors.wine,
                          labelStyle: TextStyle(
                            color: _guests == number
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: _submitting
                              ? null
                              : (_) {
                                  setState(() => _guests = number);
                                  _checkAvailability();
                                },
                        ),
                    ],
                  ),
                const SizedBox(height: 30),
                Text('Día de la visita', style: titleStyle),
                const SizedBox(height: 6),
                Text(
                  'Solo aparecen fechas en las que el restaurante atiende y puede recibir una reserva de dos horas.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_loadingOptions)
                  const LinearProgressIndicator()
                else if (_days.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage == null
                            ? 'No hay fechas reservables durante los próximos 14 días.'
                            : 'No se pudieron consultar las fechas disponibles.',
                      ),
                      TextButton.icon(
                        onPressed: _loadOptions,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Volver a consultar'),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    height: 88,
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
                          label: '${_shortDay(date)}, ${_longDate(date)}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDate = date;
                                      _selectedTime = null;
                                      _availableCount = null;
                                      _checkingAvailability = false;
                                      _errorMessage = null;
                                      _requestVersion++;
                                    });
                                  },
                            child: Container(
                              width: 78,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.wine
                                    : AppColors.card,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.wine
                                      : AppColors.line,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _shortDay(date),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.inkSoft,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${date.day} ${_shortMonth(date)}',
                                    style: GoogleFonts.piazzolla(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
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
                const SizedBox(height: 30),
                Text('Hora de llegada', style: titleStyle),
                const SizedBox(height: 6),
                Text(
                  'Cada opción deja dos horas dentro del horario de atención.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final slot in slots)
                      ChoiceChip(
                        label: Text(slot),
                        selected: _selectedTime == slot,
                        selectedColor: AppColors.wine,
                        labelStyle: TextStyle(
                          color: _selectedTime == slot
                              ? Colors.white
                              : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: _submitting
                            ? null
                            : (_) {
                                setState(() => _selectedTime = slot);
                                _checkAvailability();
                              },
                      ),
                  ],
                ),
                if (_checkingAvailability) ...[
                  const SizedBox(height: 12),
                  const Text('Comprobando mesas disponibles...'),
                ] else if (_availableCount != null && _availableCount! > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_availableCount!} ${_availableCount == 1 ? 'mesa disponible' : 'mesas disponibles'} para este horario.',
                    style: const TextStyle(
                      color: AppColors.sage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Text('Peticiones especiales', style: titleStyle),
                const SizedBox(height: 6),
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
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.paperDeep,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedDate == null || _selectedTime == null
                        ? 'Selecciona día y hora para completar tu solicitud.'
                        : '${_longDate(_selectedDate!)} · $_selectedTime · $_guests ${_guests == 1 ? 'persona' : 'personas'} · 2 horas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: AppColors.card,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      _submitting ||
                          _loadingOptions ||
                          _checkingAvailability ||
                          _days.isEmpty ||
                          _maxGuests == 0
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wine,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Solicitar reserva'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
