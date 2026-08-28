import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/widgets/movil/ui/app_avatar.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/widgets/movil/restaurant/favorite_heart.dart';

/// Pantalla principal rediseñada.
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
        (r.address ?? r.zone).toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  List<Restaurant> _getTrending(List<Restaurant> all) {
    final sorted = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }
  
  List<Restaurant> _getForYou(List<Restaurant> all) {
    final sorted = [...all]..shuffle(); // Random para demo
    return sorted.take(5).toList();
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
      return const Center(child: CircularProgressIndicator(color: AppColors.wine));
    }

    final trending = _getTrending(allRestaurants);
    final forYou = _getForYou(allRestaurants);
    final heroRest = allRestaurants.isNotEmpty ? allRestaurants.first : null;
    
    final bool isSearchingOrFiltering = _selected != null || _searchQuery.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Header de saludo
          SliverToBoxAdapter(child: _Header()),
          
          // 2. Buscador inteligente
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: _SearchBar(onChanged: (q) => setState(() => _searchQuery = q)),
            ),
          ),
          
          // 3. Fila de "antojos"
          SliverToBoxAdapter(
            child: _CravingsRow(
              selected: _selected,
              onSelect: (c) => setState(() => _selected = _selected == c ? null : c),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Si hay filtro seleccionado o búsqueda, mostramos la lista.
          if (isSearchingOrFiltering) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: Text('Resultados de búsqueda', 
                  style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filtered = _getFiltered(allRestaurants);
                  if (filtered.isEmpty) return const _NoResults();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                    child: _VerticalCard(restaurant: filtered[index], onTap: () => _navToDetail(context, filtered[index])),
                  );
                },
                childCount: _getFiltered(allRestaurants).isEmpty ? 1 : _getFiltered(allRestaurants).length,
              ),
            ),
          ] else ...[
            // 4. Plan de la noche (Hero)
            if (heroRest != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: _HeroCard(restaurant: heroRest, onTap: () => _navToDetail(context, heroRest)),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // 5. Tendencias en el valle (Bento)
            if (trending.length >= 3)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text('Tendencias en el valle', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: SizedBox(
                        height: 260,
                        child: Row(
                          children: [
                            // Izquierda: grande
                            Expanded(
                              flex: 5,
                              child: _BentoCard(restaurant: trending[0], onTap: () => _navToDetail(context, trending[0])),
                            ),
                            const SizedBox(width: 14),
                            // Derecha: dos pequeñas apiladas
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  Expanded(child: _BentoCard(restaurant: trending[1], small: true, onTap: () => _navToDetail(context, trending[1]))),
                                  const SizedBox(height: 14),
                                  Expanded(child: _BentoCard(restaurant: trending[2], small: true, onTap: () => _navToDetail(context, trending[2]))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // 6. Para ti (Tarjetas verticales)
            if (forYou.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text('Para ti', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        scrollDirection: Axis.horizontal,
                        itemCount: forYou.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 150,
                            child: _VerticalCard(restaurant: forYou[index], onTap: () => _navToDetail(context, forYou[index])),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName ?? '';
    final firstName = displayName.trim().isEmpty ? 'Chapaco' : displayName.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarija · hoy hace 24°', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '¿Qué antojo traes hoy, $firstName?',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28, height: 1.15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.paperDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              AppAvatar(name: displayName.isEmpty ? null : displayName, photoUrl: auth.photoUrl, radius: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Silpancho, vino, zona...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                border: InputBorder.none,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.paperDeep, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.mic_none_rounded, color: AppColors.ink, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CravingsRow extends StatelessWidget {
  final Cuisine? selected;
  final ValueChanged<Cuisine> onSelect;
  const _CravingsRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cravings = [
      {'cuisine': Cuisine.tipico, 'icon': Icons.kebab_dining_rounded, 'color': const Color(0xFFFDE8E8), 'iconColor': AppColors.terracotta, 'label': 'Tarijeña'},
      {'cuisine': Cuisine.parrilla, 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFFF2D9), 'iconColor': AppColors.gold, 'label': 'Parrilla'},
      {'cuisine': Cuisine.vinoBar, 'icon': Icons.wine_bar_rounded, 'color': const Color(0xFFF1E6ED), 'iconColor': AppColors.wine, 'label': 'Vinos'},
      {'cuisine': Cuisine.cafe, 'icon': Icons.local_cafe_rounded, 'color': const Color(0xFFE8F1E8), 'iconColor': AppColors.sage, 'label': 'Cafés'},
      {'cuisine': Cuisine.postres, 'icon': Icons.icecream_rounded, 'color': const Color(0xFFE8EEF8), 'iconColor': const Color(0xFF5C7A99), 'label': 'Postres'},
    ];

    return SizedBox(
      height: 85,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        itemCount: cravings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final c = cravings[i];
          final isSel = selected == c['cuisine'];
          return GestureDetector(
            onTap: () => onSelect(c['cuisine'] as Cuisine),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSel ? c['iconColor'] as Color : c['color'] as Color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isSel ? [BoxShadow(color: (c['iconColor'] as Color).withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))] : [],
                  ),
                  child: Icon(c['icon'] as IconData, color: isSel ? Colors.white : c['iconColor'] as Color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(c['label'] as String, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _HeroCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppShadows.cardStrong,
          image: restaurant.photoUrl != null ? DecorationImage(image: NetworkImage(restaurant.photoUrl!), fit: BoxFit.cover) : null,
          color: AppColors.wineSoft,
        ),
        child: Stack(
          children: [
            // Degradado
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black87],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            // Ribbon de descuento
            Positioned(
              top: 16,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('15% OFF', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
            // Corazon
            Positioned(
              top: 16,
              right: 16,
              child: FavoriteHeart(restaurantId: restaurant.id, onDark: true, size: 24),
            ),
            // Contenido inferior
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍷 El plan de la noche', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(restaurant.name, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${restaurant.cuisine.label} · ${restaurant.price}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white30, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Ver restaurante →', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 11)),
                      ),
                    ],
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

class _BentoCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool small;
  final VoidCallback onTap;
  const _BentoCard({required this.restaurant, this.small = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.cardSoft,
          image: restaurant.photoUrl != null ? DecorationImage(image: NetworkImage(restaurant.photoUrl!), fit: BoxFit.cover) : null,
          color: AppColors.wineSoft,
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: small ? 12 : 16,
              right: small ? 12 : 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: small ? 16 : 22, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(restaurant.address ?? restaurant.zone, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _VerticalCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.cardSoft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.wineSoft,
                    image: restaurant.photoUrl != null ? DecorationImage(image: NetworkImage(restaurant.photoUrl!), fit: BoxFit.cover) : null,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        Text(restaurant.rating.toString(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteHeart(restaurantId: restaurant.id, onDark: true, size: 18),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${restaurant.cuisine.label} · ${restaurant.price}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.inkSoft.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No encontramos resultados', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}