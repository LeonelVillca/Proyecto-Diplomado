part of '../../../screens/movil/restaurantes/restaurant_detail_screen.dart';

class BarraResenasRestaurante extends StatelessWidget {
  const BarraResenasRestaurante({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        border: Border(top: BorderSide(color: ConsumerColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(LucideIcons.penLine, size: 17),
              label: const Text('Escribir una reseña'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ConsumerColors.wine,
                side: const BorderSide(color: ConsumerColors.wine),
                backgroundColor: ConsumerColors.card,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BarraReservaRestaurante extends StatelessWidget {
  final Restaurant restaurant;
  const BarraReservaRestaurante({required this.restaurant});

  void _openReservationScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        border: Border(top: BorderSide(color: ConsumerColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _openReservationScreen(context),
              icon: const Icon(LucideIcons.calendarCheck, size: 18),
              label: const Text('Reservar una mesa'),
            ),
          ),
        ),
      ),
    );
  }
}
