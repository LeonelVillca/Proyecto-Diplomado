import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class DetailMenuTab extends StatelessWidget {
  const DetailMenuTab({super.key, required this.dishes});
  final List<DishItem> dishes;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.inkSoft),
              const SizedBox(height: 12),
              Text('Menú no disponible', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
    }

    // Simulamos "Destacados" tomando los primeros 4 platos (o los mas caros)
    final highlights = [...dishes]..sort((a, b) => b.price.compareTo(a.price));
    final topHighlights = highlights.take(4).toList();

    // Agrupamos por categorias
    final Map<String, List<DishItem>> byCategory = {};
    for (var d in dishes) {
      byCategory.putIfAbsent(d.category, () => []).add(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topHighlights.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text('Destacados', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 156,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: topHighlights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _HighlightCard(dish: topHighlights[index]),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Grillas por categoria
        ...byCategory.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Text(entry.key.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.inkSoft, letterSpacing: 1.0)),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 1.5, color: AppColors.line)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) => _GridDishCard(dish: entry.value[index]),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final DishItem dish;
  const _HighlightCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 104,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paperDeep,
              borderRadius: BorderRadius.circular(16),
              image: dish.photoUrl != null ? DecorationImage(image: NetworkImage(dish.photoUrl!), fit: BoxFit.cover) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 12),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.wine,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(16)),
                    ),
                    child: Text('Bs ${dish.price.toInt()}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(dish.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _GridDishCard extends StatelessWidget {
  final DishItem dish;
  const _GridDishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.paperDeep,
              borderRadius: BorderRadius.circular(16),
              image: dish.photoUrl != null ? DecorationImage(image: NetworkImage(dish.photoUrl!), fit: BoxFit.cover) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 14),
                  ),
                ),
                if (!dish.available)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('Agotado', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.red)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(dish.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(dish.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text('Bs ${dish.price.toInt()}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.wine, fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}
