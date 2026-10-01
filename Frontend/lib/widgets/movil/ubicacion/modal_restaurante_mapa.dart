part of '../../../screens/movil/location/location_screen.dart';

class ModalRestauranteMapa extends StatelessWidget {
  const ModalRestauranteMapa({required this.restaurant, required this.onClose});

  final Restaurant restaurant;
  final VoidCallback onClose;

  void _abrirDetalleRestaurante(BuildContext context) {
    onClose();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.photoUrl ?? restaurant.logoUrl;
    return Material(
      color: ConsumerColors.card,
      borderRadius: BorderRadius.circular(24),
      elevation: 10,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 100,
                height: 108,
                child: imageUrl == null
                    ? _imagenAlternativa()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagenAlternativa(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ConsumerColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(3),
                          child: Icon(LucideIcons.x, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: ConsumerColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewCount} reseñas)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ConsumerColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${restaurant.cuisineLabel} · ${restaurant.zone}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ConsumerColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen
                          ? ConsumerColors.successSoft
                          : ConsumerColors.paperDeep,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'Abierto ahora' : 'Cerrado ahora',
                      style: TextStyle(
                        color: restaurant.isOpen
                            ? ConsumerColors.success
                            : ConsumerColors.inkSoft,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _abrirDetalleRestaurante(context),
                      child: const Text(
                        'Ver restaurante',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenAlternativa() => const ColoredBox(
    color: ConsumerColors.paperDeep,
    child: Center(
      child: Icon(LucideIcons.utensils, size: 36, color: ConsumerColors.wine),
    ),
  );
}
