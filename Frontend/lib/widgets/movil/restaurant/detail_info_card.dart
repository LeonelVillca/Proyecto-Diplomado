import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';

/// Tarjeta de informacion principal: nombre, rating, tipo, ubicacion y badges.
class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de badges superiores
          Row(
            children: [
              _PromoChip(label: '15% OFF en Vinos'),
              const SizedBox(width: 8),
              _RatingChip(rating: restaurant.rating, count: restaurant.reviewCount),
            ],
          ),

          const SizedBox(height: 12),

          // Nombre del restaurante
          Text(
            restaurant.name,
            style: GoogleFonts.piazzolla(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          // Metadata: tipo, precio, estado
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaItem(icon: Icons.restaurant_menu_rounded, label: restaurant.cuisine.label),
              _MetaItem(icon: Icons.attach_money_rounded, label: restaurant.price),
              _MetaItem(
                icon: Icons.access_time_rounded,
                label: restaurant.isOpen ? 'Abierto ahora' : 'Cerrado',
                color: restaurant.isOpen ? const Color(0xFF2E8B57) : AppColors.secondaryText,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Direccion / zona
          _MetaItem(icon: Icons.place_rounded, label: restaurant.zone),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.wine.withAlpha(14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.wine.withAlpha(40)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.wine),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            '$rating ($count)',
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.manrope(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
