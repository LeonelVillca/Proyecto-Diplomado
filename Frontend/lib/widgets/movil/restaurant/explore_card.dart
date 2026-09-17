import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';

class _C {
  static const surface = AppColors.card;
  static const surface2 = Color(0xFF232533);
  static const text = AppColors.ink;
  static const textMid = AppColors.inkSoft;
  static const textSoft = AppColors.inkSoft;
  static const accent = AppColors.wine;
}

class ExploreCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const ExploreCard({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: _C.surface2,
                  child: restaurant.photoUrl != null
                      ? Image.network(restaurant.photoUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.restaurant_rounded, color: Colors.white54, size: 40),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      restaurant.cuisine.label,
                      style: GoogleFonts.poppins(fontSize: 11, color: _C.textSoft),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: _C.accent, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${restaurant.rating.toStringAsFixed(1)}(${restaurant.reviewCount})',
                          style: GoogleFonts.poppins(fontSize: 11, color: _C.textMid),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, color: _C.textSoft, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '~${restaurant.waitMinutes}min',
                          style: GoogleFonts.poppins(fontSize: 11, color: _C.textSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                'Reservar',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
