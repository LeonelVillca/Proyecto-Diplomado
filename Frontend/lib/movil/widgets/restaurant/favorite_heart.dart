import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../providers/favorites_provider.dart';

/// Corazón de favorito conectado al [FavoritesStore].
class FavoriteHeart extends StatelessWidget {
  const FavoriteHeart({
    super.key,
    required this.restaurantId,
    this.size = 20,
    this.onDark = true,
  });

  final String restaurantId;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final isFavorite = favorites.isFavorite(restaurantId);

    return Material(
      color: onDark ? Colors.black.withAlpha(42) : Colors.black.withAlpha(14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => favorites.toggle(restaurantId),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(size * 0.28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isFavorite),
              size: size,
              color: isFavorite
                  ? AppColors.wine
                  : (onDark ? Colors.white : AppColors.secondaryText),
            ),
          ),
        ),
      ),
    );
  }
}