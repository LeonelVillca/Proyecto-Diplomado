import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/widgets/movil/restaurant/favorite_heart.dart';

// ── Aliases de la paleta oficial Mesa Chapaca ────────────────────────
class _C {
  static const bg       = AppColors.paper;        // crema fondo
  static const surface  = AppColors.card;          // blanco roto tarjetas
  static const surface2 = AppColors.paperDeep;     // crema más profunda
  static const accent   = AppColors.gold;          // dorado principal
  static const accentBg = Color(0xFFF5EEE0);       // variante clara del dorado
  static const text     = AppColors.ink;           // tinta oscura principal
  static const textMid  = AppColors.inkSoft;       // gris medio
  static const textSoft = AppColors.inkSoft;       // gris suave
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
      result = result.where((r) =>
        r.name.toLowerCase().contains(q) ||
        r.cuisine.label.toLowerCase().contains(q) ||
        (r.address ?? r.zone).toLowerCase().contains(q),
      ).toList();
    }
    return result;
  }

  List<Restaurant> _getRecommended(List<Restaurant> all) {
    final sorted = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(8).toList();
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

    final recommended = _getRecommended(allRestaurants);
    final filtered = _getFiltered(allRestaurants);
    final isFiltering = _selected != null || _searchQuery.isNotEmpty;

    return Container(
      color: _C.bg,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── 1. Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _HomeHeader()),

            // ── 2. Buscador ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _SearchBar(onChanged: (q) => setState(() => _searchQuery = q)),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

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
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ExploreCard(
                        restaurant: filtered[i],
                        onTap: () => _navToDetail(context, filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.75,
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
                    height: 290,
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

              // Chips de categorías
              SliverToBoxAdapter(
                child: _CategoryChips(
                  selected: _selected,
                  onSelect: (c) => setState(() => _selected = _selected == c ? null : c),
                  onReset: () => setState(() => _selected = null),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Grilla 2 columnas
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ExploreCard(
                      restaurant: allRestaurants[i],
                      onTap: () => _navToDetail(context, allRestaurants[i]),
                    ),
                    childCount: allRestaurants.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
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

  static TextStyle _sectionTitle() => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: _C.text,
    letterSpacing: -0.3,
  );

  static TextStyle _sectionSub() => GoogleFonts.poppins(
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
        ? 'Chapaco'
        : displayName.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Logo box
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/icon_app.png',
                fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          // Saludo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $firstName 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: _C.accent, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      'Tarija, Bolivia 🇧🇴',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _C.textSoft,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notificaciones
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _C.text, size: 22),
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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _C.textSoft, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.poppins(fontSize: 14, color: _C.text),
              decoration: InputDecoration(
                hintText: 'Buscar restaurantes...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: _C.textSoft),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: _C.textMid, size: 18),
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
  final Cuisine? selected;
  final ValueChanged<Cuisine> onSelect;
  final VoidCallback onReset;
  const _CategoryChips({required this.selected, required this.onSelect, required this.onReset});

  static const _items = [
    (label: 'Todos',    cuisine: null),
    (label: 'Parrilla', cuisine: Cuisine.parrilla),
    (label: 'Casero',   cuisine: Cuisine.tipico),
    (label: 'Pasta',    cuisine: Cuisine.pastas),
    (label: 'Café',     cuisine: Cuisine.cafe),
    (label: 'Vinos',    cuisine: Cuisine.vinoBar),
    (label: 'Postres',  cuisine: Cuisine.postres),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = _items[i];
          final isSel = item.cuisine == null
              ? selected == null
              : selected == item.cuisine;
          return GestureDetector(
            onTap: () {
              if (item.cuisine != null) onSelect(item.cuisine!);
              else onReset();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? _C.accent : _C.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.black : _C.textMid,
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _C.surface,
          image: restaurant.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(restaurant.photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Scrim inferior
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE5000000)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // Corazón favorito
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FavoriteHeart(restaurantId: restaurant.id, onDark: true, size: 20),
                ),
              ),
            ),

            // Info inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge rating + tipo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _C.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.black, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${restaurant.cuisine.label} · ${restaurant.reviewCount} reseñas',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nombre
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Dirección
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: _C.accent, size: 13),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            restaurant.address ?? restaurant.zone,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botón Reservar
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.black, size: 15),
                              const SizedBox(width: 8),
                              Text(
                                'Reservar',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Tarjeta de la grilla "Explora"  (2 columnas)
// ──────────────────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _ExploreCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: _C.surface2,
                  child: restaurant.photoUrl != null
                      ? Image.network(restaurant.photoUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.restaurant_rounded, color: _C.textSoft, size: 40),
                ),
                // Corazón
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FavoriteHeart(restaurantId: restaurant.id, onDark: true, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + favorito
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      restaurant.cuisine.label,
                      style: GoogleFonts.poppins(fontSize: 11, color: _C.textSoft),
                    ),
                    const Spacer(),
                    // Rating + capacidad
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: _C.accent, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${restaurant.rating.toStringAsFixed(1)}(${restaurant.reviewCount})',
                          style: GoogleFonts.poppins(fontSize: 11, color: _C.textMid),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, color: _C.textSoft, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '~${restaurant.waitMinutes}min',
                          style: GoogleFonts.poppins(fontSize: 11, color: _C.textSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botón Reservar
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.black, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                'Reservar',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          Icon(Icons.search_off_rounded, size: 52, color: _C.textSoft.withAlpha(120)),
          const SizedBox(height: 14),
          Text(
            'No encontramos resultados',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _C.textMid),
          ),
        ],
      ),
    );
  }
}