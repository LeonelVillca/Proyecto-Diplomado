import 'package:flutter/widgets.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/services/movil/restaurante_cliente_service.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/movil/reservation.dart';

class RestauranteController extends ChangeNotifier {
  final RestauranteClienteService? _service;
  
  bool _isLoading = true;
  List<Restaurant> _restaurants = [];
  String? _errorMessage;

  RestauranteController(String? token) : _service = token != null ? RestauranteClienteService(token) : null {
    _cargarRestaurantes();
  }

  bool get isLoading => _isLoading;
  List<Restaurant> get restaurants => _restaurants;
  String? get errorMessage => _errorMessage;

  // Mock data quitada. Por ahora devolvemos listas vacías.
  List<dynamic> get promos => [];
  List<dynamic> get zones => [];
  List<Reservation> get reservations => [];

  Future<void> _cargarRestaurantes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_service == null) {
      _restaurants = [];
      _errorMessage = 'No hay sesión activa para cargar restaurantes.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _restaurants = await _service!.obtenerRestaurantes();
    } catch (e) {
      debugPrint('Error en backend: $e');
      _errorMessage = 'Error al cargar restaurantes desde el servidor.';
      _restaurants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DishItem>> obtenerPlatos(String restauranteId) async {
    if (_service == null) return [];
    try {
      return await _service!.obtenerPlatosRestaurante(restauranteId);
    } catch (e) {
      debugPrint('Error al cargar platos del backend: $e');
      return []; // Devolver vacío si falla
    }
  }

  Future<List<ReviewItem>> obtenerResenas(String restauranteId) async {
    if (_service == null) return [];
    try {
      return await _service!.obtenerResenasRestaurante(restauranteId);
    } catch (e) {
      debugPrint('Error al cargar reseñas del backend: $e');
      return [];
    }
  }

  Future<void> _cargarRestaurantesSilencioso() async {
    if (_service == null) return;
    try {
      _restaurants = await _service!.obtenerRestaurantes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error recargando restaurantes silenciosamente: $e');
    }
  }

  Future<void> crearResena(String restauranteId, int idUsuario, int calificacion, String comentario) async {
    if (_service == null) throw Exception('No session');
    await _service!.crearResena(restauranteId, idUsuario, calificacion, comentario);
    await _cargarRestaurantesSilencioso();
  }

  Future<void> toggleFavorito(String restauranteId, int idUsuario, bool isFavorite) async {
    if (_service == null) throw Exception('No session');
    await _service!.toggleFavorito(restauranteId, idUsuario, isFavorite);
  }

  Future<List<String>> obtenerFavoritos(int idUsuario) async {
    if (_service == null) return [];
    try {
      return await _service!.obtenerFavoritosUsuario(idUsuario);
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
      return [];
    }
  }
}

class RestauranteScope extends InheritedNotifier<RestauranteController> {
  const RestauranteScope({
    super.key,
    required RestauranteController controller,
    required super.child,
  }) : super(notifier: controller);

  static RestauranteController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<RestauranteScope>()
        : context.getInheritedWidgetOfExactType<RestauranteScope>();
    assert(scope != null, 'Se requiere un RestauranteScope por encima del widget.');
    return scope!.notifier!;
  }
}
