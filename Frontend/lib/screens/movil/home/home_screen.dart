import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/widgets/movil/restaurant/explore_card.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';
import 'package:frontend/screens/movil/notifications/notifications_screen.dart';
import 'package:frontend/services/movil/notifications_service.dart';

part 'inicio/controlador_inicio.dart';
part '../../../widgets/movil/inicio/encabezado_inicio.dart';
part '../../../widgets/movil/inicio/barra_busqueda_inicio.dart';
part '../../../widgets/movil/inicio/categorias_inicio.dart';
part '../../../widgets/movil/inicio/tarjeta_recomendada_inicio.dart';
part '../../../widgets/movil/inicio/sin_resultados_inicio.dart';

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

  void _showCategoryFilter(BuildContext context, List<Restaurant> restaurants) {
    final categories = _categoriasDisponibles(restaurants);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _C.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            Text('Filtrar por categoría', style: _sectionTitle()),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(LucideIcons.layoutGrid),
              title: const Text('Todos'),
              trailing: _selected == null
                  ? const Icon(LucideIcons.check, color: _C.accent)
                  : null,
              onTap: () {
                setState(() => _selected = null);
                Navigator.pop(sheetContext);
              },
            ),
            ...categories.map(
              (cuisine) => ListTile(
                leading: Icon(cuisine.icon),
                title: Text(cuisine.label),
                trailing: _selected == cuisine
                    ? const Icon(LucideIcons.check, color: _C.accent)
                    : null,
                onTap: () {
                  setState(() => _selected = cuisine);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
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
    final filtered = _filtrarRestaurantes(allRestaurants);
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
            SliverToBoxAdapter(child: EncabezadoInicio()),

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
                child: BarraBusquedaInicio(
                  onChanged: (q) => setState(() => _searchQuery = q),
                  onFilterTap: () =>
                      _showCategoryFilter(context, allRestaurants),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (allRestaurants.isNotEmpty)
              SliverToBoxAdapter(
                child: ChipsCategoriaInicio(
                  categories: _categoriasDisponibles(allRestaurants),
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
                const SliverToBoxAdapter(child: SinResultadosInicio())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExploreCard(
                        restaurant: filtered[i],
                        onTap: () =>
                            _abrirDetalleRestaurante(context, filtered[i]),
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
                    height: 180,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: recommended.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (context, i) => TarjetaRecomendadaInicio(
                        restaurant: recommended[i],
                        onTap: () =>
                            _abrirDetalleRestaurante(context, recommended[i]),
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
                      onTap: () =>
                          _abrirDetalleRestaurante(context, allRestaurants[i]),
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
