import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/widgets/movil/restaurant/detail_hero.dart';
import 'package:frontend/widgets/movil/restaurant/detail_info_card.dart';
import 'package:frontend/widgets/movil/restaurant/detail_info_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_menu_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_reviews_tab.dart';
import 'package:frontend/widgets/movil/restaurant/reservation_modal.dart';

/// Pantalla de detalle de un restaurante.
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  static const _tabs = ['Menu', 'Informacion', 'Resenas'];
  List<DishItem>? _dishes;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // NestedScrollView: header colapsa al hacer scroll en las tabs
          NestedScrollView(
            headerSliverBuilder: (context, _) => [
              // Hero con galeria de fotos
              SliverToBoxAdapter(
                child: DetailHero(
                  images: mockGalleryImages,
                  restaurantName: widget.restaurant.name,
                ),
              ),
              // Tarjeta de informacion principal
              SliverToBoxAdapter(
                child: DetailInfoCard(restaurant: widget.restaurant),
              ),
              // TabBar fija al hacer scroll
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: AppColors.background,
                toolbarHeight: 0,
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  controller: _tabCtrl,
                  labelColor: AppColors.wine,
                  unselectedLabelColor: AppColors.secondaryText,
                  indicatorColor: AppColors.wine,
                  indicatorWeight: 2.5,
                  labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ],
            // TabBarView: cada tab tiene su propio scroll independiente
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _TabScrollWrapper(
                  child: _dishes == null
                      ? const Center(child: CircularProgressIndicator())
                      : DetailMenuTab(dishes: _dishes!),
                ),
                _TabScrollWrapper(child: DetailInfoTab(restaurant: widget.restaurant, schedule: mockSchedule)),
                _TabScrollWrapper(child: DetailReviewsTab(reviews: mockReviews, avgRating: widget.restaurant.rating)),
              ],
            ),
          ),

          // Barra inferior de reserva fija (siempre visible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReserveBar(restaurant: widget.restaurant),
          ),
        ],
      ),
    );
  }
}

/// Envuelve cada tab en un SingleChildScrollView con padding inferior
/// para que el boton de "Reservar" no tape el contenido.
class _TabScrollWrapper extends StatelessWidget {
  const _TabScrollWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      child: child,
    );
  }
}

// ── Barra de reserva sticky ───────────────────────────────────────────────────
class _ReserveBar extends StatelessWidget {
  const _ReserveBar({required this.restaurant});
  final Restaurant restaurant;

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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.sheet,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => _showReservationModal(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.wine,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Reservar una Mesa',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
