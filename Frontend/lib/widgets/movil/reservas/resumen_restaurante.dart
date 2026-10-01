part of '../../../screens/movil/reservations/reservation_screen.dart';

extension _ResumenRestaurante on _ReservationScreenState {
  Widget _construirResumenRestaurante() => Container(
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
                    child: Icon(Icons.restaurant, color: ConsumerColors.wine),
                  )
                : Image.network(
                    widget.restaurant.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: ConsumerColors.paperDeep,
                      child: Icon(Icons.restaurant, color: ConsumerColors.wine),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.restaurant.cuisineLabel +
                          ' · ' +
                          widget.restaurant.zone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ResumenRestauranteReserva extends StatelessWidget {
  const ResumenRestauranteReserva({super.key, required this.pantalla});
  final _ReservationScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._construirResumenRestaurante();
}
