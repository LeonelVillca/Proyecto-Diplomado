import 'package:flutter/material.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/favorites_controller.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';

/// Corazón de favorito conectado al [FavoritesController].
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
    
    // AuthScope y RestauranteScope para persistencia
    final authController = AuthScope.of(context, listen: false);
    final restauranteController = RestauranteScope.of(context, listen: false);

    return Material(
      color: onDark ? Colors.black.withAlpha(42) : Colors.black.withAlpha(14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () async {
          final isFavNow = !isFavorite;
          favorites.toggle(restaurantId); // Actualiza UI inmediatamente (optimista)
          
          final userId = authController.idUsuario;
          if (userId != null) {
            try {
              await restauranteController.toggleFavorito(restaurantId, userId, isFavNow);
            } catch (e) {
              // Si falla, revertimos
              favorites.toggle(restaurantId);
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar favorito')));
              }
            }
          } else {
             favorites.toggle(restaurantId); // Revertir
             if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para guardar favoritos')));
             }
          }
        },
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