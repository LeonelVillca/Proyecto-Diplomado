import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// Avatar circular con iniciales. Si se provee [photoUrl] muestra la foto.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.name,
    this.photoUrl,
    this.radius = 22,
    this.color,
  });

  final String? name;
  final String? photoUrl;
  final double radius;
  final Color? color;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return 'MC';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.wine;

    if (photoUrl != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover),
          border: Border.all(color: Colors.white.withAlpha(120), width: 2),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sunset, bg],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(120), width: 2),
      ),
      child: Text(
        _initials,
        style: GoogleFonts.montserrat(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}