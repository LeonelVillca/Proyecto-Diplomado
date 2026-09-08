import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/controllers/movil/favorites_controller.dart';
import 'package:frontend/widgets/movil/restaurant/explore_card.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restauranteCtrl = RestauranteScope.of(context);
    final allRestaurants = restauranteCtrl.restaurants;
    final favCtrl = FavoritesScope.of(context);

    // Filtrar los restaurantes cuyo ID esté en el store de favoritos
    final favoriteRestaurants = allRestaurants.where((r) => favCtrl.isFavorite(r.id)).toList();

    return SafeArea(
      child: favoriteRestaurants.isEmpty
          ? _buildEmptyState(context)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('Tus Favoritos', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: favoriteRestaurants.length,
                      itemBuilder: (context, index) {
                        final r = favoriteRestaurants[index];
                        return ExploreCard(
                          restaurant: r,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.paperDeep, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border_rounded, size: 40, color: AppColors.wine),
          ),
          const SizedBox(height: 24),
          Text('Aún no tienes favoritos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 12),
          Text('Guarda los restaurantes que más te gusten para tenerlos siempre a mano.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}