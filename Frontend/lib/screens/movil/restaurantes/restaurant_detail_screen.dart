import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/widgets/movil/restaurant/reservation_modal.dart';
import 'package:frontend/widgets/movil/restaurant/detail_menu_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_info_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_reviews_tab.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  int _activeTab = 0;
  List<DishItem>? _dishes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDishes();
    });
  }

  Future<void> _loadDishes() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final plates = await ctrl.obtenerPlatos(widget.restaurant.id);
    if (mounted) {
      setState(() => _dishes = plates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Foto de portada (hero)
              SliverToBoxAdapter(
                child: _HeroSection(restaurant: widget.restaurant),
              ),
              
              // 2. Hoja de informacion (superpuesta)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
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
                        
                        // Badges (Ribbon + Abierto)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              _buildRibbon(),
                              const SizedBox(width: 8),
                              _buildOpenBadge(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Titulo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Text(
                            widget.restaurant.name,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Chips horizontales
                        SizedBox(
                          height: 36,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _IconChip(icon: Icons.star_rounded, label: widget.restaurant.rating.toString(), iconColor: AppColors.gold),
                              const SizedBox(width: 8),
                              _IconChip(icon: Icons.restaurant_rounded, label: widget.restaurant.cuisine.label, iconColor: AppColors.inkSoft),
                              const SizedBox(width: 8),
                              _IconChip(icon: Icons.attach_money_rounded, label: widget.restaurant.price, iconColor: AppColors.inkSoft),
                              const SizedBox(width: 8),
                              _IconChip(icon: Icons.map_rounded, label: 'A 2 km', iconColor: AppColors.sage),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Direccion
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 18, color: AppColors.inkSoft),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.restaurant.address ?? widget.restaurant.zone,
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
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 4. Barra de reserva
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyReserveBar(restaurant: widget.restaurant),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
  
  Widget _buildOpenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sage.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Abierto ahora', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.sage, fontSize: 11)),
    );
  }
  
  Widget _buildTabContent() {
    if (_activeTab == 0) {
      if (_dishes == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
      return DetailMenuTab(dishes: _dishes!);
    } else if (_activeTab == 1) {
      return DetailInfoTab(restaurant: widget.restaurant, schedule: widget.restaurant.schedule);
    } else {
      return DetailReviewsTab(reviews: const [], avgRating: widget.restaurant.rating);
    }
  }
}

class _HeroSection extends StatelessWidget {
  final Restaurant restaurant;
  const _HeroSection({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final images = restaurant.gallery.isNotEmpty 
        ? restaurant.gallery 
        : (restaurant.photoUrl != null ? [restaurant.photoUrl!] : []);
    final cover = images.isNotEmpty ? images.first : null;

    return Container(
      height: 300, // un poco mas de 260px para el overlap
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.wineSoft,
        image: cover != null ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover) : null,
      ),
      child: Stack(
        children: [
          // Degradado superior para que se vean los botones
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.black54, Colors.transparent]),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                  Row(
                    children: [
                      _RoundBtn(icon: Icons.share_rounded, onTap: () {}),
                      const SizedBox(width: 8),
                      _RoundBtn(icon: Icons.favorite_border_rounded, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Miniaturas de galeria (solo si hay fotos)
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 22,
              child: Row(
                children: List.generate(images.length > 4 ? 4 : images.length, (idx) {
                  return Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(image: NetworkImage(images[idx]), fit: BoxFit.cover),
                    ),
                    child: idx == 3 && images.length > 4
                        ? Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: Text('+${images.length - 4}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        : null,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _IconChip({required this.icon, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedSelector({required this.tabs, required this.activeIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.paperDeep,
            borderRadius: BorderRadius.circular(15),
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
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
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isActive ? AppColors.wine : AppColors.inkSoft,
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

  void _showReservationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReservationModal(restaurant: restaurant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.paper.withOpacity(0.0), AppColors.paper.withOpacity(0.9), AppColors.paper],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(22, 40, 22, MediaQuery.of(context).padding.bottom + 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: AppColors.wine.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: FilledButton(
          onPressed: () => _showReservationModal(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.wine,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Reservar una Mesa',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
