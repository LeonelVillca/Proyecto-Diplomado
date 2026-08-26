import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';
import 'package:frontend/widgets/movil/navigation/app_bottom_nav.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.paperDeep, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border_rounded, size: 40, color: AppColors.wine),
            ),
            const SizedBox(height: 24),
            Text('Aún no tienes favoritos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            Text('Guarda los restaurantes que más te gusten para tenerlos siempre a mano.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Explorar restaurantes', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}