part of '../../../screens/movil/restaurantes/restaurant_detail_screen.dart';

class PestanasDetalleRestaurante extends SliverPersistentHeaderDelegate {
  PestanasDetalleRestaurante({
    required this.activeIndex,
    required this.onChanged,
  });

  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: ConsumerColors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SelectorPestanasDetalle(
          tabs: const ['Menú', 'Información', 'Reseñas'],
          activeIndex: activeIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PestanasDetalleRestaurante oldDelegate) =>
      activeIndex != oldDelegate.activeIndex ||
      onChanged != oldDelegate.onChanged;
}

class SelectorPestanasDetalle extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const SelectorPestanasDetalle({
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: ConsumerColors.card,
            border: Border.all(color: ConsumerColors.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: activeIndex * tabWidth,
                top: 4,
                bottom: 4,
                width: tabWidth,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ConsumerColors.wine,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(tabs.length, (idx) {
                  final isActive = idx == activeIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(idx),
                      child: Center(
                        child: Text(
                          tabs[idx],
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : ConsumerColors.inkSoft,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
