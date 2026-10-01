part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _SelectorFechasReserva on _ReservationScreenState {
  List<Widget> _construirSelectorFechas() => [
    const SizedBox(height: 22),
    Row(
      children: [
        Expanded(
          child: Text(
            '¿Cuándo?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text('Próximos 7 días', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    const SizedBox(height: 12),
    if (_loadingOptions)
      const SizedBox(
        height: 84,
        child: Center(
          child: CircularProgressIndicator(color: ConsumerColors.wine),
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
                reservationDateKey(date) == reservationDateKey(_selectedDate!);
            return Semantics(
              button: true,
              selected: selected,
              label: this._encabezadoDia(date) + ', ' + this._fechaLarga(date),
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
                        this._actualizarDisponibilidadHorarios();
                      },
                child: Container(
                  width: 62,
                  decoration: BoxDecoration(
                    color: selected ? ConsumerColors.wine : ConsumerColors.card,
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
                        this._encabezadoDia(date),
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
                          color: selected ? Colors.white : ConsumerColors.ink,
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        this._mesCorto(date),
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
  ];
}

class SelectorFechasReserva extends StatelessWidget {
  const SelectorFechasReserva({super.key, required this.pantalla});
  final _ReservationScreenState pantalla;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: pantalla._construirSelectorFechas(),
  );
}
