part of '../../../screens/movil/home/home_screen.dart';

class ChipsCategoriaInicio extends StatelessWidget {
  final List<Cuisine> categories;
  final Cuisine? selected;
  final ValueChanged<Cuisine> onSelect;
  final VoidCallback onReset;
  const ChipsCategoriaInicio({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cuisine = i == 0 ? null : categories[i - 1];
          final isSel = cuisine == null
              ? selected == null
              : selected == cuisine;
          return GestureDetector(
            onTap: () {
              if (cuisine != null)
                onSelect(cuisine);
              else
                onReset();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? _C.accent : _C.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSel ? _C.accent : ConsumerColors.line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cuisine == null
                        ? LucideIcons.layoutGrid
                        : switch (cuisine) {
                            Cuisine.parrilla => LucideIcons.flame,
                            Cuisine.vinoBar => LucideIcons.wine,
                            Cuisine.cafe => LucideIcons.coffee,
                            Cuisine.postres => LucideIcons.cookie,
                            _ => LucideIcons.utensils,
                          },
                    size: 15,
                    color: isSel ? Colors.white : _C.textMid,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    cuisine?.label ?? 'Todos',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : _C.textMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Tarjeta del carrusel "Recomendados"  (grande, imagen de fondo)
// ──────────────────────────────────────────────────────────────────────
