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
import 'package:frontend/widgets/movil/restaurant/create_review_modal.dart';
import 'package:frontend/screens/movil/restaurantes/galeria_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  static const double _heroHeight = 325;
  static const double _summaryHeight = 174;
  static const double _summaryOverlap = 28;

  int _activeTab = 0;
  List<DishItem>? _dishes;
  List<ReviewItem>? _reviews;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDishes();
      _loadReviews();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final openStatus = _openStatus();
    return Scaffold(
      backgroundColor: ConsumerColors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: _heroHeight + _summaryHeight - _summaryOverlap,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _heroHeight,
                      child: _HeroSection(restaurant: widget.restaurant),
                    ),
                    Positioned(
                      top: 10,
                      left: 8,
                      child: _RoundBtn(
                        icon: LucideIcons.arrowLeft,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: _heroHeight - _summaryOverlap,
                      left: 0,
                      right: 0,
                      child: _buildRestaurantSummary(context, openStatus),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _RestaurantTabsHeader(
                activeIndex: _activeTab,
                onChanged: _selectTab,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _activeTab == 0 ? 0 : 20,
                  14,
                  _activeTab == 0 ? 0 : 20,
                  20,
                ),
                child: KeyedSubtree(
                  key: ValueKey(_activeTab),
                  child: _buildTabContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _activeTab == 2
          ? _StickyReviewBar(onTap: () => _showCreateReview(context))
          : _StickyReserveBar(restaurant: widget.restaurant),
    );
  }

  void _selectTab(int index) {
    if (index == _activeTab) return;
    setState(() => _activeTab = index);
    final tabsTop = _heroHeight + _summaryHeight - _summaryOverlap;
    if (_scrollController.hasClients && _scrollController.offset > tabsTop) {
      _scrollController.jumpTo(tabsTop);
    }
  }

  Widget _buildRestaurantSummary(BuildContext context, String? openStatus) {
    return Container(
      width: double.infinity,
      height: _summaryHeight,
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: ConsumerColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.restaurant.reviewCount > 0)
                _RatingSummary(restaurant: widget.restaurant),
              _buildCuisineBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: ConsumerColors.wine,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.restaurant.address ?? widget.restaurant.zone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ConsumerColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (openStatus != null) ...[
            const SizedBox(height: 8),
            _OpenStatusChip(label: openStatus),
          ],
        ],
      ),
    );
  }

  String? _openStatus() {
    final schedules = widget.restaurant.schedule;
    if (schedules.isEmpty) return null;

    final now = DateTime.now();
    const days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    String normalize(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    int? toMinutes(String value) {
      final parts = value.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null ||
          minute == null ||
          hour > 24 ||
          minute > 59 ||
          (hour == 24 && minute != 0)) {
        return null;
      }
      return hour * 60 + minute;
    }

    final today = now.weekday - 1;
    final yesterday = (today + 6) % 7;
    final current = now.hour * 60 + now.minute;
    var hasValidSchedule = false;
    for (final item in schedules) {
      final day = days.indexOf(normalize(item.dayLabel));
      final opens = toMinutes(item.openTime);
      final closes = toMinutes(item.closeTime);
      if (day < 0 || opens == null || closes == null || opens == closes) {
        continue;
      }
      hasValidSchedule = true;

      if (day == today) {
        final isOpen = closes > opens
            ? current >= opens && current < closes
            : current >= opens;
        if (isOpen) {
          return 'Abierto ahora · hasta ${item.closeTime.substring(0, 5)}';
        }
      }
      if (day == yesterday && closes < opens && current < closes) {
        return 'Abierto ahora · hasta ${item.closeTime.substring(0, 5)}';
      }
    }
    return hasValidSchedule ? 'Cerrado ahora' : null;
  }

  void _showCreateReview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateReviewModal(
        restaurantId: widget.restaurant.id,
        onSuccess: _loadReviews,
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
        mainAxisSize: MainAxisSize.min,
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
        reviews: _reviews!,
        avgRating: avg > 0 ? avg : widget.restaurant.rating,
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
      height: 244,
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
              bottom: 36,
              // Reserva el lado izquierdo para el botón de volver de la barra.
              left: 76,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ConsumerColors.paper.withOpacity(0.96),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: ConsumerColors.ink, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: ConsumerColors.gold, size: 16),
        const SizedBox(width: 4),
        Text(
          restaurant.rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
        ),
        const SizedBox(width: 3),
        Text(
          '(${restaurant.reviewCount} reseñas)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _OpenStatusChip extends StatelessWidget {
  const _OpenStatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isOpen = label.startsWith('Abierto');
    final color = isOpen ? ConsumerColors.success : ConsumerColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? ConsumerColors.successSoft : ConsumerColors.paperDeep,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock3, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantTabsHeader extends SliverPersistentHeaderDelegate {
  _RestaurantTabsHeader({required this.activeIndex, required this.onChanged});

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
        child: _SegmentedSelector(
          tabs: const ['Menú', 'Información', 'Reseñas'],
          activeIndex: activeIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RestaurantTabsHeader oldDelegate) =>
      activeIndex != oldDelegate.activeIndex ||
      onChanged != oldDelegate.onChanged;
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

class _StickyReviewBar extends StatelessWidget {
  const _StickyReviewBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        border: Border(top: BorderSide(color: ConsumerColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(LucideIcons.penLine, size: 17),
              label: const Text('Escribir una reseña'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ConsumerColors.wine,
                side: const BorderSide(color: ConsumerColors.wine),
                backgroundColor: ConsumerColors.card,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        border: Border(top: BorderSide(color: ConsumerColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _openReservationScreen(context),
              icon: const Icon(LucideIcons.calendarCheck, size: 18),
              label: const Text('Reservar una mesa'),
            ),
          ),
        ),
      ),
    );
  }
}
