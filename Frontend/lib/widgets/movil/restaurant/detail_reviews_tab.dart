import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class DetailReviewsTab extends StatefulWidget {
  const DetailReviewsTab({
    super.key,
    required this.reviews,
    required this.avgRating,
  });

  final List<ReviewItem> reviews;
  final double avgRating;

  @override
  State<DetailReviewsTab> createState() => _DetailReviewsTabState();
}

class _DetailReviewsTabState extends State<DetailReviewsTab> {
  String _filter = 'Todas';

  List<ReviewItem> get _visibleReviews {
    final visible = _filter == '5 estrellas'
        ? widget.reviews.where((review) => review.rating == 5).toList()
        : List<ReviewItem>.of(widget.reviews);
    if (_filter == 'Recientes') {
      visible.sort((a, b) {
        final aDate = _reviewDate(a.date);
        final bDate = _reviewDate(b.date);
        if (aDate == null) return bDate == null ? 0 : 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    }
    return visible;
  }

  DateTime? _reviewDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _visibleReviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingSummary(avgRating: widget.avgRating, reviews: widget.reviews),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ReviewFilterChip(
                label: 'Todas',
                selected: _filter == 'Todas',
                onTap: () => setState(() => _filter = 'Todas'),
              ),
              const SizedBox(width: 8),
              _ReviewFilterChip(
                label: '5 estrellas',
                selected: _filter == '5 estrellas',
                onTap: () => setState(() => _filter = '5 estrellas'),
              ),
              const SizedBox(width: 8),
              _ReviewFilterChip(
                label: 'Recientes',
                selected: _filter == 'Recientes',
                onTap: () => setState(() => _filter = 'Recientes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          _EmptyReviews(hasReviews: widget.reviews.isNotEmpty)
        else
          ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.avgRating, required this.reviews});
  final double avgRating;
  final List<ReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    final total = reviews.length;
    final counts = List<int>.generate(
      5,
      (index) => reviews.where((review) => review.rating == 5 - index).length,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConsumerColors.line),
        boxShadow: ConsumerShadows.cardSoft,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 42, height: 1),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < avgRating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: ConsumerColors.gold,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total ${total == 1 ? 'reseña' : 'reseñas'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Column(
              children: List.generate(
                5,
                (index) => _RatingBarRow(
                  stars: 5 - index,
                  count: counts[index],
                  total: total,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBarRow extends StatelessWidget {
  const _RatingBarRow({
    required this.stars,
    required this.count,
    required this.total,
  });
  final int stars;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${stars}★',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: total == 0 ? 0 : count / total,
                backgroundColor: ConsumerColors.paperDeep,
                valueColor: const AlwaysStoppedAnimation(ConsumerColors.wine),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewFilterChip extends StatelessWidget {
  const _ReviewFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ConsumerColors.wine : ConsumerColors.card,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? ConsumerColors.wine : ConsumerColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : ConsumerColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.hasReviews});
  final bool hasReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ConsumerColors.line),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.messageCircle,
            size: 30,
            color: ConsumerColors.inkSoft,
          ),
          const SizedBox(height: 8),
          Text(
            hasReviews
                ? 'No hay reseñas con este filtro'
                : 'Aún no hay reseñas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            hasReviews
                ? 'Prueba otra opción para ver más opiniones.'
                : 'Sé la primera persona en compartir su experiencia.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewItem review;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ConsumerColors.line),
        boxShadow: ConsumerShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ConsumerColors.sage,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(review.authorName),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.date,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 13,
                    color: ConsumerColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${review.comment}”',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ConsumerColors.ink,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          if (review.ownerReply != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              decoration: BoxDecoration(
                color: ConsumerColors.wineSoft.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: ConsumerColors.wine, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.store,
                        size: 12,
                        color: ConsumerColors.wine,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Respuesta del restaurante',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ConsumerColors.wine,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    review.ownerReply!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.4),
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
