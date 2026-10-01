part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _BarraConfirmacionReserva on _ReservationScreenState {
  Widget _construirBarraConfirmacion(bool habilitada) => Container(
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
                              this._mesCorto(_selectedDate!) +
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
                onPressed: habilitada ? _enviarReserva : null,
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
  );
}

class BarraConfirmacionReserva extends StatelessWidget {
  const BarraConfirmacionReserva({
    super.key,
    required this.pantalla,
    required this.habilitada,
  });
  final _ReservationScreenState pantalla;
  final bool habilitada;
  @override
  Widget build(BuildContext context) =>
      pantalla._construirBarraConfirmacion(habilitada);
}
