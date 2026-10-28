part of '../restaurant_detail_screen.dart';

extension _ServicioDetalleRestaurante on _RestaurantDetailScreenState {
  Future<void> _cargarPlatos() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final restauranteId = widget.restaurant.id;
    final solicitud = ++_solicitudPlatos;
    try {
      final plates = await ctrl.obtenerPlatos(restauranteId);
      if (mounted && solicitud == _solicitudPlatos) {
        setState(() {
          _dishes = plates;
          _errorPlatos = null;
        });
      }
    } catch (_) {
      if (mounted && solicitud == _solicitudPlatos) {
        setState(() {
          _dishes = null;
          _errorPlatos =
              'No se pudieron recuperar los menús y platos. Revisa tu conexión e inténtalo de nuevo.';
        });
      }
    }
  }

  Future<void> _cargarResenas() async {
    final ctrl = RestauranteScope.of(context, listen: false);
    final restauranteId = widget.restaurant.id;
    final revs = await ctrl.obtenerResenas(restauranteId);
    if (mounted && widget.restaurant.id == restauranteId) {
      setState(() => _reviews = revs);
    }
  }
}
