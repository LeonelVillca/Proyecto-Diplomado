import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/widgets/movil/restaurant/explore_card.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';

// ── Aliases de la paleta oficial Mesa Chapaca ────────────────────────
class _C {
  static const bg = ConsumerColors.paper; // crema fondo
  static const surface = ConsumerColors.card; // blanco roto tarjetas
  static const accent = ConsumerColors.wine;
  static const text = ConsumerColors.ink; // tinta oscura principal
  static const textMid = ConsumerColors.inkSoft; // gris medio
  static const textSoft = ConsumerColors.inkSoft; // gris suave
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Cuisine? _selected;
  String _searchQuery = '';

  List<Restaurant> _getFiltered(List<Restaurant> all) {
    var result = all;
    if (_selected != null) {
      result = result.where((r) => r.cuisine == _selected).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                r.cuisine.label.toLowerCase().contains(q) ||
                (r.address ?? r.zone).toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  void _navToDetail(BuildContext context, Restaurant r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restauranteCtrl = RestauranteScope.of(context);
    final allRestaurants = restauranteCtrl.restaurants;

    if (restauranteCtrl.isLoading) {
      return Container(
        color: _C.bg,
        child: const Center(child: CircularProgressIndicator(color: _C.accent)),
      );
    }

    final recommended = restauranteCtrl.ranking;
    final filtered = _getFiltered(allRestaurants);
    final isFiltering = _selected != null || _searchQuery.isNotEmpty;

    return Container(
      color: _C.bg,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── 1. Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _HomeHeader()),

            if (restauranteCtrl.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: InlineErrorBanner(
                    message: restauranteCtrl.errorMessage!,
                  ),
                ),
              ),

            // ── 2. Buscador ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _SearchBar(
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (allRestaurants.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryChips(
                  categories: allRestaurants
                      .map((r) => r.cuisine)
                      .toSet()
                      .toList(),
                  selected: _selected,
                  onSelect: (c) =>
                      setState(() => _selected = _selected == c ? null : c),
                  onReset: () => setState(() => _selected = null),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            if (isFiltering) ...[
              // ── Resultados de búsqueda / filtro ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text('Resultados', style: _sectionTitle()),
                ),
              ),
              if (filtered.isEmpty)
                const SliverToBoxAdapter(child: _NoResults())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExploreCard(
                        restaurant: filtered[i],
                        onTap: () => _navToDetail(context, filtered[i]),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // ── 3. Recomendados (Carrusel grande) ─────────────────
              if (recommended.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recomendados', style: _sectionTitle()),
                        const SizedBox(height: 4),
                        Text('Los mejores para reservar', style: _sectionSub()),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 156,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: recommended.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, i) => _RecommendedCard(
                        restaurant: recommended[i],
                        onTap: () => _navToDetail(context, recommended[i]),
                      ),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 36)),

              // ── 4. Explora restaurantes ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explora restaurantes', style: _sectionTitle()),
                      const SizedBox(height: 4),
                      Text('Elige por tipo de cocina', style: _sectionSub()),
                    ],
                  ),
                ),
              ),

              // Lista compacta de restaurantes reales
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: allRestaurants.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExploreCard(
                      restaurant: allRestaurants[i],
                      onTap: () => _navToDetail(context, allRestaurants[i]),
                    ),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  static TextStyle _sectionTitle() => const TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _C.text,
    letterSpacing: -0.3,
  );

  static TextStyle _sectionSub() => const TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _C.textSoft,
  );
}

// ──────────────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName ?? '';
    final firstName = displayName.trim().isEmpty
        ? 'bienvenido'
        : displayName.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Avatar de la sesión
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ConsumerColors.sage,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              firstName[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Saludo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 12,
                    color: _C.textSoft,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Hola, '),
                      TextSpan(
                        text: '$firstName.',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: _C.accent,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: _C.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Barra de búsqueda
// ──────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ConsumerColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: _C.textSoft, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 14,
                color: _C.text,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar restaurantes...',
                hintStyle: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 14,
                  color: _C.textSoft,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Chips de categoría
// ──────────────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<Cuisine> categories;
  final Cuisine? selected;
  final ValueChanged<Cuisine> onSelect;
  final VoidCallback onReset;
  const _CategoryChips({
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
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
class _RecommendedCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _RecommendedCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: ConsumerColors.line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 112,
                    height: 118,
                    child: restaurant.photoUrl == null
                        ? const ColoredBox(
                            color: ConsumerColors.paperDeep,
                            child: Icon(LucideIcons.utensils, color: _C.accent),
                          )
                        : Image.network(
                            restaurant.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: ConsumerColors.paperDeep,
                              child: Icon(
                                LucideIcons.utensils,
                                color: _C.accent,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _C.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (restaurant.reviewCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: ConsumerColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.text,
                              ),
                            ),
                            Text(
                              ' (' + restaurant.reviewCount.toString() + ')',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _C.textSoft,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.cuisine.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textSoft,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Ver restaurante',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// El _ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart
// El ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart

// ──────────────────────────────────────────────────────────────────────
// Sin resultados
// ──────────────────────────────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 52,
            color: _C.textSoft.withAlpha(120),
          ),
          const SizedBox(height: 14),
          Text(
            'No encontramos resultados',
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
