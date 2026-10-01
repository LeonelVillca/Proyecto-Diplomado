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

part 'gestion_mesas/servicio_mesas.dart';
part 'gestion_mesas/controlador_mesas.dart';
part '../../../widgets/admin/gestion_mesas/selector_horarios_mesas.dart';
part '../../../widgets/admin/gestion_mesas/resumen_mesas.dart';
part '../../../widgets/admin/gestion_mesas/tarjeta_mesa.dart';

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
  final Set<int> _mesasActualizando = {};
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

  List<Map<String, dynamic>> get _mesasFiltradas {
    return _ocupacion.where((mesa) {
      return _filtroEstado == 'todas' ||
          _estadoEnConsulta(mesa) == _filtroEstado;
    }).toList();
  }

  List<DateTime> get _diasProximos {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(7, (index) => start.add(Duration(days: index)));
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
    int reservadas = _countForState('reservada');
    int ocupadas = _countForState('ocupada');
    int inactivas = _countForState('inactiva');
    final mesasFiltradas = _mesasFiltradas;
    final fechaLabel =
        '${_fechaConsulta.day.toString().padLeft(2, '0')}/${_fechaConsulta.month.toString().padLeft(2, '0')}/${_fechaConsulta.year}';
    final horaLabel = _horariosDisponibles.isEmpty
        ? 'Sin atención'
        : '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';

    final stats = [
      (
        'Capacidad total',
        '$capacidadTotal',
        Icons.people_alt_outlined,
        AdminTheme.textMuted,
      ),
      ('Libres', '$libres', Icons.chair_alt_rounded, AdminTheme.success),
      (
        'Ocupadas',
        '$ocupadas',
        Icons.restaurant_rounded,
        AdminTheme.primaryColor,
      ),
      (
        'Reservadas',
        '$reservadas',
        Icons.event_available_rounded,
        AdminTheme.gold,
      ),
      ('Inactivas', '$inactivas', Icons.block_rounded, AdminTheme.textMuted),
    ];

    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final compact = pageConstraints.maxWidth <= 640;
        final horizontalPadding = compact ? 18.0 : 34.0;
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              34,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  kicker: 'SALÓN',
                  titleBefore: 'Gestión de ',
                  titleEmphasis: 'Mesas.',
                  description:
                      'Toca una mesa para cambiar su estado solo en el horario elegido (1 hora).',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _abrirModalMesa(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nueva mesa'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SelectorHorariosMesas(
                  pantalla: this,
                  fechaLabel: fechaLabel,
                  horaLabel: horaLabel,
                ),
                if (_errorOcupacion != null) ...[
                  const SizedBox(height: 10),
                  AdminSurface(
                    padding: const EdgeInsets.all(14),
                    radius: AdminTheme.mediumRadius,
                    child: Text(
                      'No se pudo verificar la disponibilidad: $_errorOcupacion',
                      style: AdminTheme.bodyStyle.copyWith(
                        color: AdminTheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 17,
                      color: AdminTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Disponibilidad para '),
                            TextSpan(
                              text: _nombreDia(_fechaConsulta),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AdminTheme.textDark,
                              ),
                            ),
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: horaLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AdminTheme.textDark,
                              ),
                            ),
                            TextSpan(text: ' · $libres disponibles'),
                          ],
                        ),
                        style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 1080
                        ? 5
                        : constraints.maxWidth > 640
                        ? 3
                        : 2;
                    final gap = 12.0;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var index = 0; index < stats.length; index++)
                          SizedBox(
                            width: columns == 2 && index == 4
                                ? constraints.maxWidth
                                : cardWidth,
                            child: _buildResumenCard(
                              stats[index].$1,
                              stats[index].$2,
                              stats[index].$3,
                              stats[index].$4,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AdminSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  radius: AdminTheme.pillRadius,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FiltroEstadoMesas(
                          pantalla: this,
                          label: 'Todos',
                          valor: 'todas',
                          count: _ocupacion.length,
                        ),
                        _buildFiltroPill(
                          'Libres',
                          'libre',
                          _countForState('libre'),
                        ),
                        _buildFiltroPill(
                          'Ocupadas',
                          'ocupada',
                          _countForState('ocupada'),
                        ),
                        _buildFiltroPill(
                          'Reservadas',
                          'reservada',
                          _countForState('reservada'),
                        ),
                        _buildFiltroPill(
                          'Inactivas',
                          'inactiva',
                          _countForState('inactiva'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AdminSurface(
                  padding: const EdgeInsets.all(16),
                  radius: AdminTheme.mediumRadius,
                  child: _isLoading || _cargandoOcupacion
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              color: AdminTheme.primaryColor,
                            ),
                          ),
                        )
                      : _errorOcupacion != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'No mostramos disponibilidad sin poder verificarla.',
                              style: AdminTheme.bodyStyle,
                            ),
                          ),
                        )
                      : _horariosDisponibles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'El restaurante no atiende en la fecha seleccionada.',
                              style: AdminTheme.bodyStyle,
                            ),
                          ),
                        )
                      : mesasFiltradas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'No hay mesas para mostrar.',
                              style: AdminTheme.bodyStyle,
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: compact ? 210 : 250,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: 238,
                              ),
                          itemCount: mesasFiltradas.length,
                          itemBuilder: (context, index) =>
                              TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  '${_fechaConsulta}_${index}_${mesasFiltradas[index]['idMesa']}',
                                ),
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 450 + index * 35,
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 12 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                                child: TarjetaMesaAdmin(
                                  pantalla: this,
                                  datosMesa: mesasFiltradas[index],
                                ),
                              ),
                        ),
                ),
                const SizedBox(height: 12),
                LeyendaEstadosMesas(pantalla: this),
              ],
            ),
          ),
        );
      },
    );
  }
}
