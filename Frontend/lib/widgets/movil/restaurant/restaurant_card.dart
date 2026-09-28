import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/widgets/movil/ui/rating_label.dart';

/// Tarjeta vertical destacada de restaurante:
/// portada en degradado, estado de apertura, datos y "Reservar".
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  final Restaurant restaurant;
  final VoidCallback? onTap;

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.cardStrong,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _openDetail(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cover(restaurant: restaurant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
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
                            style: GoogleFonts.piazzolla(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RatingLabel(
                          rating: restaurant.rating,
                          reviewCount: restaurant.reviewCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 13, color: AppColors.secondaryText),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            restaurant.zone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaTag(
                          icon: Icons.payments_rounded,
                          label: restaurant.price,
                        ),
                        _MetaTag(
                          icon: restaurant.cuisine.icon,
                          label: restaurant.cuisineLabel,
                          emphasize: true,
                        ),
                        if (restaurant.isBestSeller)
                          const _MetaTag(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Top',
                            hot: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: FilledButton.icon(
                              onPressed: () => _openDetail(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.wine,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.event_available_rounded,
                                  size: 18),
                              label: Text(
                                'Reservar mesa',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _WaitBadge(minutes: restaurant.waitMinutes),
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

/// Portada del restaurante: degradado, emoji y estado.
class _Cover extends StatelessWidget {
  const _Cover({required this.restaurant});

  final Restaurant restaurant;

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
              fontSize: 46,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
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

          // Estado de apertura.
          Positioned(
            left: 12,
            top: 12,
            child: _OpenBadge(isOpen: restaurant.isOpen),
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? const Color(0xFF2E8B57) : const Color(0xFFB3343B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(232),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Abierto' : 'Cerrado',
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña de metadatos (precio, cocina, destacados).
class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.icon,
    required this.label,
    this.emphasize = false,
    this.hot = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final color = hot
        ? AppColors.sunset
        : emphasize
            ? AppColors.wine
            : Color.lerp(AppColors.gold, Colors.black, 0.08)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(hot ? 22 : 12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de espera ("~15 min").
class _WaitBadge extends StatelessWidget {
  const _WaitBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 15, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            '$minutes min',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
