import 'package:flutter/widgets.dart';

/// Guarda los restaurantes marcados como favoritos.
///
/// Es un `ChangeNotifier` simple expuesto vía [FavoritesScope], de modo que
/// cualquier tarjeta puede alternar el corazón y la lista de "Favoritos" se
/// actualiza sola.
class FavoritesStore extends ChangeNotifier {
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
}

/// Permite exponer [FavoritesStore] a todo el árbol sin dependencias externas.
class FavoritesScope extends InheritedNotifier<FavoritesStore> {
  const FavoritesScope({
    super.key,
    required FavoritesStore favoritesStore,
    required super.child,
  }) : super(notifier: favoritesStore);

  static FavoritesStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'Se requiere un FavoritesScope por encima del widget.');
    return scope!.notifier!;
  }
}