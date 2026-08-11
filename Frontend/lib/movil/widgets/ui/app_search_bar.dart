import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// Barra de búsqueda redondeada con acción de filtros.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.onSubmitted,
    this.onFilterTap,
  });

  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.secondaryText, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Buscar restaurante, cocina o zona…',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppColors.secondaryText,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: AppColors.background,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onFilterTap,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.wine,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}