import 'package:flutter/widgets.dart';

/// Guarda los restaurantes marcados como favoritos.
///
/// Es un `ChangeNotifier` simple expuesto vía [FavoritesScope], de modo que
/// cualquier tarjeta puede alternar el corazón y la lista de "Favoritos" se
/// actualiza sola.
class FavoritesController extends ChangeNotifier {
  final Set<String> _ids = {};

  int get count => _ids.length;

  bool isFavorite(String id) => _ids.contains(id);

  List<String> get asList => _ids.toList();

  void toggle(String id) {
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
    notifyListeners();
  }

  void loadFavorites(List<String> ids) {
    _ids.clear();
    _ids.addAll(ids);
    notifyListeners();
  }
}

/// Permite exponer [FavoritesController] a todo el árbol sin dependencias externas.
class FavoritesScope extends InheritedNotifier<FavoritesController> {
  const FavoritesScope({
    super.key,
    required FavoritesController favoritesController,
    required super.child,
  }) : super(notifier: favoritesController);

  static FavoritesController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<FavoritesScope>()
        : context.getInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'Se requiere un FavoritesScope por encima del widget.');
    return scope!.notifier!;
  }
}