import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

/// Tab de resenas con resumen de puntuacion y lista de comentarios.
class DetailReviewsTab extends StatelessWidget {
  const DetailReviewsTab({super.key, required this.reviews, required this.avgRating});

  final List<ReviewItem> reviews;
  final double avgRating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingSummary(avgRating: avgRating, total: reviews.length),
        const SizedBox(height: 8),
        ...reviews.map((r) => _ReviewCard(review: r)),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.avgRating, required this.total});
  final double avgRating;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(avgRating.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.wine)),
              Text('de 5.0',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondaryText)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < avgRating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.gold,
                    size: 20,
                  )),
                ),
                const SizedBox(height: 4),
                Text('$total resenas verificadas',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewItem review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: autor + puntuacion + fecha
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.wine.withAlpha(20),
                child: Text(review.authorName[0],
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: AppColors.wine)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName,
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(review.date,
                        style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.secondaryText)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.gold,
                  size: 14,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.ink, height: 1.5)),

          // Respuesta del propietario si existe
          if (review.ownerReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.wine.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: AppColors.wine, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Respuesta del propietario',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.wine)),
                  const SizedBox(height: 3),
                  Text(review.ownerReply!,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.secondaryText, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
