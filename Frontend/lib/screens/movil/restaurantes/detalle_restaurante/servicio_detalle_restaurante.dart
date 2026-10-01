part of '../restaurant_detail_screen.dart';

extension _ServicioDetalleRestaurante on _RestaurantDetailScreenState {
  Future<void> _cargarPlatos() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final plates = await ctrl.obtenerPlatos(widget.restaurant.id);
    if (mounted) {
      setState(() => _dishes = plates);
    }
  }

  Future<void> _cargarResenas() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final revs = await ctrl.obtenerResenas(widget.restaurant.id);
    if (mounted) {
      setState(() => _reviews = revs);
    }
  }
}
