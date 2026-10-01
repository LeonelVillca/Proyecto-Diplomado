part of '../../../screens/admin/mesas/gestion_mesas_screen.dart';

extension _SelectorHorariosMesas on _GestionMesasScreenState {
  Widget _buildSelector(String fechaLabel, String horaLabel) {
    final selectedDate = DateTime(
      _fechaConsulta.year,
      _fechaConsulta.month,
      _fechaConsulta.day,
    );
    final lunch = _horariosDisponibles
        .where((slot) => int.parse(slot.substring(0, 2)) < 17)
        .toList();
    final dinner = _horariosDisponibles
        .where((slot) => int.parse(slot.substring(0, 2)) >= 17)
        .toList();
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      radius: AdminTheme.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: AdminTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELIGE CUÁNDO',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Consulta el salón',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_cargandoOcupacion)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Actualizar disponibilidad',
                  onPressed: _consultarOcupacion,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          this._selectorLabel('DÍA', 'Próximos días'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final day in this._diasProximos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: this._buildDayChip(day, selectedDate),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: AdminTheme.border),
          ),
          this._selectorLabel(
            'HORA',
            'Horario de atención · 1 hora por reserva',
          ),
          const SizedBox(height: 9),
          if (_horariosDisponibles.isEmpty)
            Text(
              'Sin horarios disponibles para este día.',
              style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
            )
          else ...[
            if (lunch.isNotEmpty)
              this._buildHourGroup('ALMUERZO', lunch, horaLabel),
            if (lunch.isNotEmpty && dinner.isNotEmpty)
              const SizedBox(height: 9),
            if (dinner.isNotEmpty)
              this._buildHourGroup('CENA', dinner, horaLabel),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              this._buildDotLegend(const Color(0xFFC4B7A3), 'Sin reservas'),
              this._buildDotLegend(AdminTheme.gold, 'Con reservas'),
              this._buildDotLegend(AdminTheme.error, 'Ocupada'),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '$fechaLabel · Los indicadores reflejan la consulta seleccionada.',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _selectorLabel(String label, String value) => Row(
    children: [
      SizedBox(
        width: 54,
        child: Text(
          label,
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AdminTheme.textMuted,
          ),
        ),
      ),
      Text(
        value,
        style: AdminTheme.bodyStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AdminTheme.textDark,
        ),
      ),
    ],
  );

  Widget _buildDayChip(DateTime date, DateTime selectedDate) {
    final slots = this._slotsParaFecha(date);
    final isOpen = this._tieneAtencionConfigurada(date);
    final canSelect = slots.isNotEmpty;
    final active = date == selectedDate;
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final labels = const ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return Tooltip(
      message: !isOpen
          ? 'Cerrado'
          : canSelect
          ? this._nombreDia(date)
          : 'Atención finalizada por hoy',
      child: InkWell(
        onTap: !canSelect || _cargandoOcupacion
            ? null
            : () => this._seleccionarDia(date),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AdminTheme.primaryColor
                : isOpen
                ? AdminTheme.surface
                : AdminTheme.background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? AdminTheme.primaryColor : AdminTheme.border,
              width: 1.4,
            ),
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: Color(0x4DBE4B24),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: isOpen ? 1 : .5,
            child: Column(
              children: [
                Text(
                  isToday ? 'HOY' : labels[date.weekday - 1],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                    color: active ? Colors.white : AdminTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: active ? Colors.white : AdminTheme.textDark,
                    decoration: isOpen ? null : TextDecoration.lineThrough,
                    decorationColor: AdminTheme.error,
                  ),
                ),
                Text(
                  !isOpen
                      ? 'Cerrado'
                      : !canSelect
                      ? 'Finalizado'
                      : (active ? 'ABIERTO' : 'Abierto'),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white70 : AdminTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourGroup(String label, List<String> slots, String horaLabel) =>
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.background,
              borderRadius: AdminTheme.pillRadius,
              border: Border.all(color: AdminTheme.border),
            ),
            child: Text(
              label,
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
          for (final slot in slots)
            this._buildHourChip(slot, slot == horaLabel),
        ],
      );

  Widget _buildHourChip(String slot, bool active) {
    final hasReservations = _ocupacion.any((mesa) => mesa['reserva'] != null);
    final isOccupied = _ocupacion.any(
      (mesa) => this._estadoEnConsulta(mesa) == 'ocupada',
    );
    final dotColor = active
        ? (isOccupied
              ? AdminTheme.error
              : hasReservations
              ? AdminTheme.gold
              : const Color(0xFFC4B7A3))
        : const Color(0xFFC4B7A3);
    return InkWell(
      onTap: _cargandoOcupacion
          ? null
          : () {
              final parts = slot.split(':').map(int.parse).toList();
              setState(
                () =>
                    _horaConsulta = TimeOfDay(hour: parts[0], minute: parts[1]),
              );
              this._consultarOcupacion();
            },
      borderRadius: AdminTheme.pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primaryColor : AdminTheme.surface,
          borderRadius: AdminTheme.pillRadius,
          border: Border.all(
            color: active ? AdminTheme.primaryColor : AdminTheme.border,
          ),
          boxShadow: active
              ? [
                  const BoxShadow(
                    color: Color(0x3DBE4B24),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? Colors.white : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AdminTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotLegend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: AdminTheme.bodyStyle.copyWith(fontSize: 10)),
    ],
  );

  String _nombreDia(DateTime date) {
    const names = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return '${names[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class SelectorHorariosMesas extends StatelessWidget {
  const SelectorHorariosMesas({
    super.key,
    required this.pantalla,
    required this.fechaLabel,
    required this.horaLabel,
  });
  final _GestionMesasScreenState pantalla;
  final String fechaLabel;
  final String horaLabel;
  @override
  Widget build(BuildContext context) =>
      pantalla._buildSelector(fechaLabel, horaLabel);
}
