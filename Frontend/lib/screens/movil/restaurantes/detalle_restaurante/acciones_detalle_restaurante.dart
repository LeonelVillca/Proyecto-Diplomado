part of '../restaurant_detail_screen.dart';

extension _AccionesDetalleRestaurante on _RestaurantDetailScreenState {
  void _seleccionarPestana(int index) {
    if (index == _activeTab) return;
    setState(() => _activeTab = index);
    final tabsTop = _heroHeight + _summaryHeight - _summaryOverlap;
    if (_scrollController.hasClients && _scrollController.offset > tabsTop) {
      _scrollController.jumpTo(tabsTop);
    }
  }

  void _mostrarCrearResena(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateReviewModal(
        restaurantId: widget.restaurant.id,
        onSuccess: _cargarResenas,
      ),
    );
  }

  Widget _construirContenidoPestana() {
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
