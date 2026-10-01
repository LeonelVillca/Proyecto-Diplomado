part of '../home_screen.dart';

extension _ControladorInicio on _HomeScreenState {
  List<Restaurant> _filtrarRestaurantes(List<Restaurant> all) {
    var result = all;
    if (_selected != null) {
      result = result
          .where(
            (r) => (r.cuisines.isEmpty ? [r.cuisine] : r.cuisines).contains(
              _selected,
            ),
          )
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result
          .where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                r.cuisineLabel.toLowerCase().contains(q) ||
                (r.address ?? r.zone).toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  void _abrirDetalleRestaurante(BuildContext context, Restaurant r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)),
    );
  }

  List<Cuisine> _categoriasDisponibles(List<Restaurant> restaurants) {
    final available = restaurants
        .expand((r) => r.cuisines.isEmpty ? [r.cuisine] : r.cuisines)
        .toSet();
    return Cuisine.values.where(available.contains).toList();
  }
}
