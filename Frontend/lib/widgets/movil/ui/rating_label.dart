import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estrellas y nota de valoración, compactas y reutilizables.
class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.rating,
    this.reviewCount,
    this.onDark = false,
    this.textColor,
  });

  final double rating;
  final int? reviewCount;
  final bool onDark;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final body = textColor ??
        (onDark ? Colors.white : const Color(0xFF3C3C43));

    final label = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: body,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFE8A33D)),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: label),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${reviewCount! >= 1000 ? '${(reviewCount! / 1000).toStringAsFixed(1)}k' : reviewCount})',
            style: label.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: onDark ? Colors.white70 : const Color(0x8A3C3C43),
            ),
          ),
        ],
      ],
    );
  }
}