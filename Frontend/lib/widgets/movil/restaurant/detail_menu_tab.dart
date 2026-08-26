import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

/// Tab de menu con filtros por categoria y lista de platos.
class DetailMenuTab extends StatefulWidget {
  const DetailMenuTab({super.key, required this.dishes});
  final List<DishItem> dishes;

  @override
  State<DetailMenuTab> createState() => _DetailMenuTabState();
}

class _DetailMenuTabState extends State<DetailMenuTab> {
  String _category = 'Todos';

  List<String> get _categories {
    final cats = widget.dishes.map((d) => d.category).toSet().toList();
    return ['Todos', ...cats];
  }

  List<DishItem> get _filtered =>
      _category == 'Todos' ? widget.dishes : widget.dishes.where((d) => d.category == _category).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros de categoria
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = cat == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.wine : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Text(cat,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.ink,
                      )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Lista de platos
        ...(_filtered.map((dish) => _DishCard(dish: dish))),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.dish});
  final DishItem dish;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dish.available ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.cardSoft,
        ),
        child: Row(
          children: [
            // Foto del plato o placeholder
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.wine.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                image: dish.photoUrl != null
                    ? DecorationImage(
                        image: AssetImage(dish.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: dish.photoUrl == null
                  ? Icon(Icons.restaurant_rounded, color: AppColors.wine.withAlpha(150), size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(dish.name,
                            style: GoogleFonts.montserrat(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ),
                      Text('Bs ${dish.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.wine)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(dish.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.secondaryText)),
                  if (!dish.available)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('No disponible',
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
