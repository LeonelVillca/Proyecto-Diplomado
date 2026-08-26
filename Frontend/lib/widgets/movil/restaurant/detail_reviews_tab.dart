import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class DetailReviewsTab extends StatelessWidget {
  const DetailReviewsTab({super.key, required this.reviews, required this.avgRating});

  final List<ReviewItem> reviews;
  final double avgRating;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppColors.inkSoft),
            const SizedBox(height: 16),
            Text('Nadie ha opinado todavía', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Comparte tu experiencia y ayuda a otros a descubrir este restaurante.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.wine, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Escribir la primera reseña', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.wine)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingSummary(avgRating: avgRating, total: reviews.length),
        const SizedBox(height: 16),
        ...reviews.map((r) => _ReviewCard(review: r)),
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
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lado izquierdo: Puntuacion
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(avgRating.toStringAsFixed(1), style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48, height: 1.0)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(
                    i < avgRating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.gold,
                    size: 14,
                  )),
                ),
                const SizedBox(height: 6),
                Text('$total reseñas verificadas', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center),
              ],
            ),
          ),
          
          Container(width: 1, height: 80, color: AppColors.line, margin: const EdgeInsets.symmetric(horizontal: 16)),
          
          // Lado derecho: Barras
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _RatingBarRow(stars: 5, percent: 0.7),
                _RatingBarRow(stars: 4, percent: 0.2),
                _RatingBarRow(stars: 3, percent: 0.1),
                _RatingBarRow(stars: 2, percent: 0.0),
                _RatingBarRow(stars: 1, percent: 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBarRow extends StatelessWidget {
  final int stars;
  final double percent;
  const _RatingBarRow({required this.stars, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(stars.toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 10, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: AppColors.paperDeep, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(height: 6, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(3))),
                ),
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
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.paperDeep, shape: BoxShape.circle),
                child: Center(
                  child: Text(review.authorName[0], style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16, color: AppColors.wine)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(review.date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.paperDeep, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Text(review.rating.toString(), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(review.comment, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.5)),

          if (review.ownerReply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wineSoft.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.wineSoft.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 16, color: AppColors.wine),
                      const SizedBox(width: 6),
                      Text('Respuesta del restaurante', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.wine)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.ownerReply!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
