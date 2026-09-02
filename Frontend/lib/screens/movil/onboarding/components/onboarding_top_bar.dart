import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';

/// Barra superior del onboarding: botón Back, dots de progreso, botón Skip.
class OnboardingTopBar extends StatelessWidget {
  final int currentPage;
  final AnimationController animationController;
  final VoidCallback onBackClick;
  final VoidCallback onSkipClick;

  const OnboardingTopBar({
    Key? key,
    required this.currentPage,
    required this.animationController,
    required this.onBackClick,
    required this.onSkipClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Botón Back (invisible en página 0) ──────────────
          AnimatedOpacity(
            opacity: currentPage > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: currentPage > 0 ? onBackClick : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.wine.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.wine,
                  size: 17,
                ),
              ),
            ),
          ),

          // ── Dots de progreso ─────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final bool isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.wine
                      : AppColors.wine.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // ── Botón Skip ───────────────────────────────────────
          AnimatedOpacity(
            opacity: currentPage < 2 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: currentPage < 2 ? onSkipClick : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Saltar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
