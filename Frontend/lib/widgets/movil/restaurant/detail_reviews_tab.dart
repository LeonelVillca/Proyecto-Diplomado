import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/widgets/movil/restaurant/create_review_modal.dart';

class DetailReviewsTab extends StatelessWidget {
  const DetailReviewsTab({
    super.key,
    required this.restaurantId,
    required this.reviews,
    required this.avgRating,
    required this.onReviewAdded,
  });

  final String restaurantId;
  final List<ReviewItem> reviews;
  final double avgRating;
  final VoidCallback onReviewAdded;

  void _showCreateReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateReviewModal(
        restaurantId: restaurantId,
        onSuccess: onReviewAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Column(
          children: [
            const Icon(
              LucideIcons.messageCircle,
              size: 48,
              color: ConsumerColors.inkSoft,
            ),
            const SizedBox(height: 16),
            Text(
              'Nadie ha opinado todavía',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte tu experiencia y ayuda a otros a descubrir este restaurante.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _showCreateReview(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ConsumerColors.wine, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Escribir la primera reseña',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: ConsumerColors.wine),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingSummary(
          avgRating: avgRating,
          total: reviews.length,
          reviews: reviews,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reseñas', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                onPressed: () => _showCreateReview(context),
                icon: const Icon(
                  LucideIcons.penLine,
                  size: 16,
                  color: ConsumerColors.wine,
                ),
                label: Text(
                  'Opinar',
                  style: TextStyle(color: ConsumerColors.wine),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.avgRating,
    required this.total,
    required this.reviews,
  });
  final double avgRating;
  final int total;
  final List<ReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    int count5 = reviews.where((r) => r.rating == 5).length;
    int count4 = reviews.where((r) => r.rating == 4).length;
    int count3 = reviews.where((r) => r.rating == 3).length;
    int count2 = reviews.where((r) => r.rating == 2).length;
    int count1 = reviews.where((r) => r.rating == 1).length;

    double p5 = total > 0 ? count5 / total : 0;
    double p4 = total > 0 ? count4 / total : 0;
    double p3 = total > 0 ? count3 / total : 0;
    double p2 = total > 0 ? count2 / total : 0;
    double p1 = total > 0 ? count1 / total : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ConsumerShadows.cardSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lado izquierdo: Puntuacion
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 48, height: 1.0),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < avgRating.floor()
                          ? Icons.star_rounded
                          : LucideIcons.star,
                      color: ConsumerColors.gold,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total reseñas verificadas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 80,
            color: ConsumerColors.line,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Lado derecho: Barras
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _RatingBarRow(stars: 5, percent: p5),
                _RatingBarRow(stars: 4, percent: p4),
                _RatingBarRow(stars: 3, percent: p3),
                _RatingBarRow(stars: 2, percent: p2),
                _RatingBarRow(stars: 1, percent: p1),
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
          Text(
            stars.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 10, color: ConsumerColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: ConsumerColors.paperDeep,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(seconds: 1),
                  curve: Curves.easeOut,
                  builder: (context, value, child) =>
                      FractionallySizedBox(widthFactor: value, child: child),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: ConsumerColors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
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
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ConsumerShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ConsumerColors.paperDeep,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.authorName[0],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      color: ConsumerColors.wine,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.date,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ConsumerColors.paperDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      review.rating.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      color: ConsumerColors.gold,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.comment,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.5),
          ),

          if (review.ownerReply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ConsumerColors.wineSoft.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ConsumerColors.wineSoft.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.reply,
                        size: 16,
                        color: ConsumerColors.wine,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Respuesta del restaurante',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          color: ConsumerColors.wine,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.ownerReply!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
