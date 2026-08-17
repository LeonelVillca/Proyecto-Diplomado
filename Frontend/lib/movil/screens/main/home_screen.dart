import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/restaurantes_mock.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/restaurant/promo_card.dart';
import '../../widgets/restaurant/restaurant_card.dart';
import '../../widgets/restaurant/restaurant_card_compact.dart';
import '../../widgets/ui/app_avatar.dart';
import '../../widgets/ui/app_filter_chip.dart';
import '../../widgets/ui/app_search_bar.dart';
import '../../widgets/ui/app_section_header.dart';

/// Pantalla principal: descubre restaurantes de Tarija.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Cuisine? _selected;

  List<Restaurant> get _all => mockRestaurants;

  List<Restaurant> get _filtered =>
      _selected == null ? _all : _all.where((r) => r.cuisine == _selected).toList();

  List<Restaurant> get _trending {
    final sorted = [..._all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  List<Cuisine> get _available =>
      Cuisine.values.where((c) => _all.any((r) => r.cuisine == c)).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _Header()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: AppSearchBar(
              onFilterTap: () => _showFilterHint(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _available.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppFilterChip(
                    label: 'Todos',
                    selected: _selected == null,
                    icon: Icons.grid_view_rounded,
                    onTap: () => setState(() => _selected = null),
                  );
                }
                final cuisine = _available[index - 1];
                return AppFilterChip(
                  label: cuisine.label,
                  icon: cuisine.icon,
                  selected: _selected == cuisine,
                  onTap: () => setState(() => _selected = cuisine),
                );
              },
            ),
          ),
        ),
        // Carrusel promocional.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 148,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.92),
                itemCount: mockPromos.length,
                itemBuilder: (context, index) =>
                    PromoCard(slide: mockPromos[index]),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        // Tendencia.
        SliverToBoxAdapter(
          child: AppSectionHeader(
            title: 'Tendencia en Tarija 🔥',
            trailingLabel: 'Ver todo',
            onTrailingTap: () => _showFilterHint(context),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: _trending.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  RestaurantCardCompact(restaurant: _trending[index]),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        // Recomendados.
        SliverToBoxAdapter(
          child: AppSectionHeader(
            title: 'Recomendados para ti',
            trailingLabel: _selected == null ? null : 'Limpiar filtro',
            onTrailingTap: _selected == null
                ? null
                : () => setState(() => _selected = null),
          ),
        ),
        if (_filtered.isEmpty)
          const SliverToBoxAdapter(child: _NoResults())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: RestaurantCard(restaurant: _filtered[index]),
              ),
              childCount: _filtered.length,
            ),
          ),
        // Espacio para que la barra flotante no tape el contenido.
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    ),
  );
  }

  void _showFilterHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtros y búsqueda avanzada — próximamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Encabezado con saludo, subtítulo y avatar del usuario.
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName ?? '';
    final firstName = displayName.trim().isEmpty
        ? 'Chapaco'
        : displayName.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $firstName! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '¿Qué te apetece hoy?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppAvatar(
            name: displayName.isEmpty ? null : displayName,
            photoUrl: auth.photoUrl,
            radius: 24,
          ),
        ],
      ),
    );
  }
}

/// Estado cuando ningún restaurante coincide con el filtro.
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.secondaryText.withAlpha(160)),
          const SizedBox(height: 12),
          Text(
            'No encontramos resultados',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}