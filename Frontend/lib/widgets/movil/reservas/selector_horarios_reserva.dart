part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _SelectorHorariosReserva on _ReservationScreenState {
  List<Widget> _construirSelectorHorarios(List<String> horarios) => [
    const SizedBox(height: 22),
    Row(
      children: [
        Expanded(
          child: Text(
            '¿A qué hora?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text('Horario local', style: Theme.of(context).textTheme.bodySmall),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              onTap: _submitting || _checkingAvailability || unavailable
                  ? null
                  : () {
                      setState(() {
                        _selectedTime = slot;
                        _availableCount = null;
                      });
                      this._comprobarDisponibilidad();
                    },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? ConsumerColors.wine : ConsumerColors.card,
                  border: Border.all(
                    color: selected ? ConsumerColors.wine : ConsumerColors.line,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _checkingAvailability && selected
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
        _availableCount.toString() + ' mesas disponibles para este horario.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: ConsumerColors.sage),
      ),
    ],
  ];
}

class SelectorHorariosReserva extends StatelessWidget {
  const SelectorHorariosReserva({
    super.key,
    required this.pantalla,
    required this.horarios,
  });
  final _ReservationScreenState pantalla;
  final List<String> horarios;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: pantalla._construirSelectorHorarios(horarios),
  );
}
