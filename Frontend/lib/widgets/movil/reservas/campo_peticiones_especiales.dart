part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _CampoPeticionesEspeciales on _ReservationScreenState {
  List<Widget> _construirPeticionesEspeciales() => [
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  ];
}

class CampoPeticionesReserva extends StatelessWidget {
  const CampoPeticionesReserva({super.key, required this.pantalla});
  final _ReservationScreenState pantalla;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: pantalla._construirPeticionesEspeciales(),
  );
}
