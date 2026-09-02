import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/widgets/movil/ui/rating_label.dart';
import 'favorite_heart.dart';

/// Tarjeta compacta para carruseles horizontales.
class RestaurantCardCompact extends StatelessWidget {
  const RestaurantCardCompact({
    super.key,
    required this.restaurant,
    this.width = 164,
    this.onTap,
  });

  final Restaurant restaurant;
  final double width;
  final VoidCallback? onTap;

  Widget _buildFallbackCover() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: restaurant.gradient,
            ),
          ),
        ),
        Center(
          child: Text(
            restaurant.emoji,
            style: const TextStyle(
              fontSize: 34,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.cardSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${restaurant.name} — próximamente.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portada.
              SizedBox(
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (restaurant.photoUrl != null)
                      Image.network(
                        restaurant.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackCover(),
                      )
                    else
                      _buildFallbackCover(),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FavoriteHeart(restaurantId: restaurant.id, size: 16),
                    ),
                  ],
                ),
              ),
              // Contenido.
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.piazzolla(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 11, color: AppColors.secondaryText),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            restaurant.zone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RatingLabel(rating: restaurant.rating),
                        Text(
                          restaurant.price,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}