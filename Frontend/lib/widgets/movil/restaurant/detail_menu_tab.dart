import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class DetailMenuTab extends StatelessWidget {
  const DetailMenuTab({super.key, required this.dishes});
  final List<DishItem> dishes;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.utensils,
                size: 40,
                color: ConsumerColors.inkSoft,
              ),
              SizedBox(height: 12),
              Text(
                'Menú no disponible',
                style: TextStyle(fontFamily: 'Fraunces', fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    final byCategory = <String, List<DishItem>>{};
    for (final dish in dishes) {
      byCategory.putIfAbsent(dish.category, () => []).add(dish);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: ConsumerColors.ink,
              ),
            ),
          ),
          for (final dish in entry.value)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: _DishRow(dish: dish),
            ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({required this.dish});
  final DishItem dish;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: ConsumerColors.card,
      border: Border.all(color: ConsumerColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: 92,
            height: 92,
            child: dish.photoUrl == null
                ? const ColoredBox(
                    color: ConsumerColors.paperDeep,
                    child: Icon(
                      LucideIcons.utensils,
                      color: ConsumerColors.wine,
                    ),
                  )
                : Image.network(
                    dish.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: ConsumerColors.paperDeep,
                      child: Icon(
                        LucideIcons.utensils,
                        color: ConsumerColors.wine,
                      ),
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
                dish.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ConsumerColors.ink,
                ),
              ),
              if (dish.description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  dish.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ConsumerColors.inkSoft,
                  ),
                ),
              ],
              const SizedBox(height: 5),
              Text(
                'Bs ${dish.price.toStringAsFixed(dish.price % 1 == 0 ? 0 : 2)}',
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: ConsumerColors.wineDark,
                ),
              ),
              if (!dish.available)
                const Text(
                  'Agotado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ConsumerColors.error,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
