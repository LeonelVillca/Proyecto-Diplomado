part of '../../../screens/movil/restaurantes/restaurant_detail_screen.dart';

class ResumenCalificacion extends StatelessWidget {
  const ResumenCalificacion({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: ConsumerColors.gold, size: 16),
        const SizedBox(width: 4),
        Text(
          restaurant.rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
        ),
        const SizedBox(width: 3),
        Text(
          '(${restaurant.reviewCount} reseñas)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class IndicadorAperturaRestaurante extends StatelessWidget {
  const IndicadorAperturaRestaurante({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isOpen = label.startsWith('Abierto');
    final color = isOpen ? ConsumerColors.success : ConsumerColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? ConsumerColors.successSoft : ConsumerColors.paperDeep,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock3, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
