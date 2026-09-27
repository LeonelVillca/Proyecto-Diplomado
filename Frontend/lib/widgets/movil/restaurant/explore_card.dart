import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant.dart';

class ExploreCard extends StatelessWidget {
  const ExploreCard({super.key, required this.restaurant, required this.onTap});
  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ConsumerColors.card,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: ConsumerColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: restaurant.photoUrl == null
                    ? const ColoredBox(
                        color: ConsumerColors.paperDeep,
                        child: Icon(
                          LucideIcons.utensils,
                          color: ConsumerColors.wine,
                        ),
                      )
                    : Image.network(
                        restaurant.photoUrl!,
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
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ConsumerColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant.cuisine.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ConsumerColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (restaurant.reviewCount > 0) ...[
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: ConsumerColors.gold,
              ),
              const SizedBox(width: 3),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ConsumerColors.ink,
                ),
              ),
            ],
            const SizedBox(width: 3),
          ],
        ),
      ),
    ),
  );
}
