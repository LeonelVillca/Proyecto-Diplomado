import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/restaurantes_mock.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/restaurant/restaurant_card.dart';
import '../../widgets/ui/app_empty_state.dart';

/// Restaurantes marcados como favoritos.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favoritos',
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  favorites.count == 1
                      ? '1 restaurante guardado'
                      : '${favorites.count} restaurantes guardados',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (favorites.count == 0)
          SliverToBoxAdapter(
            child: AppEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Aún no tienes favoritos',
              description:
                  'Toca el corazón en cualquier restaurante para guardarlo aquí.',
              actionLabel: 'Explorar restaurantes',
              onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ve a la pestaña Inicio para descubrir lugares.'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final id = favorites.asList[index];
                final restaurant =
                    mockRestaurants.firstWhere((r) => r.id == id);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: RestaurantCard(restaurant: restaurant),
                );
              },
              childCount: favorites.asList.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}