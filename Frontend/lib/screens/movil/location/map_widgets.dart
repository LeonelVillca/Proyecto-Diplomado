import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const kGoldColor = Color(0xFFC08A2D);
const kWineColor = Color(0xFFBE4B24);

/// Barra de búsqueda flotante.
class MapSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const MapSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(LucideIcons.search, color: Colors.black45, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration.collapsed(
                hintText: 'Buscar restaurante o zona...',
                hintStyle: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 13,
                  color: Colors.black38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de restaurante dentro del bottom sheet.
class RestaurantMapCard extends StatelessWidget {
  final dynamic restaurant;
  final VoidCallback? onTap;

  const RestaurantMapCard({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String tags = restaurant.tags != null && restaurant.tags.isNotEmpty
        ? restaurant.tags.first
        : 'Restaurante';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (restaurant.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  restaurant.photoUrl!,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: kWineColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.utensils,
                      color: kWineColor,
                      size: 32,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: kWineColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.utensils,
                  color: kWineColor,
                  size: 32,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tags,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: kGoldColor,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${restaurant.rating}',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
