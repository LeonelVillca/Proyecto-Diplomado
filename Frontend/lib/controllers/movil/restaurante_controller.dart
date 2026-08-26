import 'package:flutter/widgets.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/services/movil/restaurante_cliente_service.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/repositories/movil/restaurantes_mock.dart' as mock;
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

  // Mock data for UI parts that are not yet connected to backend
  List<mock.PromoSlide> get promos => mock.mockPromos;
  List<mock.Zone> get zones => mock.mockZones;
  List<Reservation> get reservations => mock.mockReservations;

  Future<void> _cargarRestaurantes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_service == null) {
      _restaurants = mock.mockRestaurants;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _restaurants = await _service!.obtenerRestaurantes();
    } catch (e) {
      _errorMessage = 'Error al cargar restaurantes: $e';
      _restaurants = mock.mockRestaurants; // Fallback to mock for testing
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DishItem>> obtenerPlatos(String restauranteId) async {
    if (_service == null) return mockDishes;
    try {
      return await _service!.obtenerPlatosRestaurante(restauranteId);
    } catch (e) {
      debugPrint('Error al cargar platos: $e');
      return mockDishes; // Fallback to mock
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
