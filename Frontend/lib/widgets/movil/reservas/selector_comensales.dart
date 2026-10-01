part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _SelectorComensales on _ReservationScreenState {
  List<Widget> _construirSelectorComensales() => [
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
                    this._actualizarDisponibilidadHorarios();
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
                    this._actualizarDisponibilidadHorarios();
                  },
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
    ),
    const SizedBox(height: 22),
  ];
}

class SelectorComensalesReserva extends StatelessWidget {
  const SelectorComensalesReserva({super.key, required this.pantalla});
  final _ReservationScreenState pantalla;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: pantalla._construirSelectorComensales(),
  );
}
