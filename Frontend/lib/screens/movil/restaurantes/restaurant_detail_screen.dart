import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/reservations/reservation_screen.dart';
import 'package:frontend/widgets/movil/restaurant/detail_menu_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_info_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_reviews_tab.dart';
import 'package:frontend/screens/movil/restaurantes/galeria_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  int _activeTab = 0;
  List<DishItem>? _dishes;
  List<ReviewItem>? _reviews;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDishes();
      _loadReviews();
    });
  }

  Future<void> _loadDishes() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final plates = await ctrl.obtenerPlatos(widget.restaurant.id);
    if (mounted) {
      setState(() => _dishes = plates);
    }
  }

  Future<void> _loadReviews() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final revs = await ctrl.obtenerResenas(widget.restaurant.id);
    if (mounted) {
      setState(() => _reviews = revs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConsumerColors.paper,
      body: Stack(
        children: [
          // La imagen se desplaza y desaparece; el título queda fijado en la barra.
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 225,
                collapsedHeight: 72,
                backgroundColor: ConsumerColors.paper,
                elevation: innerBoxIsScrolled ? 2 : 0,
                automaticallyImplyLeading: false,
                leading: _RoundBtn(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  // El nombre vive debajo de la foto; solo reaparece en la
                  // barra compacta cuando el usuario ya empezó a desplazarse.
                  title: innerBoxIsScrolled
                      ? Text(
                          widget.restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: ConsumerColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                      : null,
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 58,
                    end: 24,
                    bottom: 16,
                  ),
                  background: _HeroSection(restaurant: widget.restaurant),
                ),
              ),
            ],
            body: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  color: ConsumerColors.paper,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tirador
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Título editorial fuera de la imagen: más legible y
                    // sin competir con las miniaturas de la galería.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 30,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: ConsumerColors.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 15,
                                color: ConsumerColors.wine,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  widget.restaurant.zone,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ConsumerColors.inkSoft,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StickyReserveBar(restaurant: widget.restaurant),

                    // Badges dinámicos del restaurante
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(children: [_buildCuisineBadge()]),
                    ),
                    const SizedBox(height: 12),

                    // Chips horizontales
                    SizedBox(
                      height: 36,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (widget.restaurant.reviewCount > 0) ...[
                            _IconChip(
                              icon: Icons.star_rounded,
                              label:
                                  '${widget.restaurant.rating.toStringAsFixed(1)} (${widget.restaurant.reviewCount})',
                              iconColor: ConsumerColors.gold,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _IconChip(
                            icon: LucideIcons.utensils,
                            label: widget.restaurant.cuisine.label,
                            iconColor: ConsumerColors.inkSoft,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Direccion
                    if (widget.restaurant.address != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 18,
                              color: ConsumerColors.inkSoft,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.restaurant.address!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // 3. Selector segmentado
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _SegmentedSelector(
                        tabs: const ['Menú', 'Información', 'Reseñas'],
                        activeIndex: _activeTab,
                        onChanged: (idx) => setState(() => _activeTab = idx),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contenido de la tab activa
                    _buildTabContent(),

                    // Espacio al final
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ConsumerColors.wine.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.utensils,
            size: 13,
            color: ConsumerColors.wine,
          ),
          const SizedBox(width: 6),
          Text(
            widget.restaurant.cuisine.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ConsumerColors.wine,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTab == 0) {
      if (_dishes == null)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        );
      return DetailMenuTab(dishes: _dishes!);
    } else if (_activeTab == 1) {
      return DetailInfoTab(
        restaurant: widget.restaurant,
        schedule: widget.restaurant.schedule,
      );
    } else {
      if (_reviews == null)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        );

      double avg = 0;
      if (_reviews!.isNotEmpty) {
        avg =
            _reviews!.map((e) => e.rating).reduce((a, b) => a + b) /
            _reviews!.length;
      }

      return DetailReviewsTab(
        restaurantId: widget.restaurant.id,
        reviews: _reviews!,
        avgRating: avg > 0 ? avg : widget.restaurant.rating,
        onReviewAdded: _loadReviews,
      );
    }
  }
}

class _HeroSection extends StatefulWidget {
  final Restaurant restaurant;
  const _HeroSection({required this.restaurant});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.restaurant.gallery.isNotEmpty
        ? widget.restaurant.gallery
        : (widget.restaurant.photoUrl != null
              ? [widget.restaurant.photoUrl!]
              : <String>[]);
    final cover = images.isNotEmpty && _selectedIndex < images.length
        ? images[_selectedIndex]
        : (images.isNotEmpty ? images.first : null);

    return Container(
      height: 300, // un poco mas de 260px para el overlap
      width: double.infinity,
      decoration: BoxDecoration(
        color: ConsumerColors.wineSoft,
        image: cover != null
            ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        children: [
          // Degradado superior para que se vean los botones
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),

          // Miniaturas de galeria (solo si hay fotos)
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 22,
              child: Row(
                children: List.generate(images.length > 4 ? 4 : images.length, (
                  idx,
                ) {
                  final isLastAndMore = idx == 3 && images.length > 4;
                  final isSelected = _selectedIndex == idx && !isLastAndMore;
                  return GestureDetector(
                    onTap: () {
                      if (isLastAndMore) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GaleriaScreen(images: images, initialIndex: 3),
                          ),
                        );
                      } else {
                        setState(() {
                          _selectedIndex = idx;
                        });
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? ConsumerColors.wine
                              : Colors.white,
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(images[idx]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isLastAndMore
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+${images.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ConsumerColors.paper.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: ConsumerColors.wine.withOpacity(0.22),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: ConsumerColors.wine, size: 23),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _IconChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ConsumerColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: ConsumerColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedSelector({
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

class _StickyReserveBar extends StatelessWidget {
  final Restaurant restaurant;
  const _StickyReserveBar({required this.restaurant});

  void _openReservationScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: () => _openReservationScreen(context),
          child: Text(
            'Reservar una mesa',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
