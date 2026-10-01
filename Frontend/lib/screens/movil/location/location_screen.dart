import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;

import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/screens/movil/location/map_widgets.dart';
import 'package:frontend/models/movil/restaurant.dart';

part '../../../widgets/movil/ubicacion/fondo_alternativo_mapa.dart';
part '../../../widgets/movil/ubicacion/lista_restaurantes_mapa.dart';
part '../../../widgets/movil/ubicacion/filtro_cocina_mapa.dart';
part '../../../widgets/movil/ubicacion/modal_restaurante_mapa.dart';

const LatLng kInitialPosition = LatLng(-21.5354, -64.7296);

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapCtrl;
  late final AnimationController _pinPulse;
  String _searchQuery = '';
  Cuisine? _selectedCuisine;
  final Map<String, BitmapDescriptor> _restaurantMarkerIcons = {};
  final Set<String> _loadingMarkerIcons = {};
  Restaurant? _selectedRestaurant;

  // El mapa solo funciona en Web, Android e iOS.
  bool get _mapsSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _pinPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void dispose() {
    _pinPulse.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantMarkerIcon(Restaurant restaurant) async {
    final imageUrls = <String>{
      if (restaurant.logoUrl?.isNotEmpty == true) restaurant.logoUrl!,
      if (restaurant.photoUrl?.isNotEmpty == true) restaurant.photoUrl!,
    };
    if (imageUrls.isEmpty ||
        _restaurantMarkerIcons.containsKey(restaurant.id) ||
        !_loadingMarkerIcons.add(restaurant.id)) {
      return;
    }

    try {
      for (final imageUrl in imageUrls) {
        try {
          final response = await NetworkAssetBundle(
            Uri.parse(imageUrl),
          ).load(imageUrl);
          final codec = await ui.instantiateImageCodec(
            response.buffer.asUint8List(),
            targetWidth: 96,
            targetHeight: 96,
          );
          final frame = await codec.getNextFrame();
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const center = Offset(48, 48);
          final shadow = Paint()
            ..color = Colors.black.withAlpha(55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(const Offset(48, 50), 42, shadow);
          canvas.drawCircle(center, 43, Paint()..color = Colors.white);
          canvas.save();
          canvas.clipPath(
            Path()..addOval(Rect.fromCircle(center: center, radius: 38)),
          );
          canvas.drawImageRect(
            frame.image,
            Rect.fromLTWH(
              0,
              0,
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            ),
            const Rect.fromLTWH(10, 10, 76, 76),
            Paint()..filterQuality = FilterQuality.high,
          );
          canvas.restore();
          final image = await recorder.endRecording().toImage(96, 96);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          if (!mounted || bytes == null) return;
          setState(() {
            _restaurantMarkerIcons[restaurant.id] = BitmapDescriptor.fromBytes(
              bytes.buffer.asUint8List(),
              size: const Size(40, 40),
            );
          });
          return;
        } catch (_) {
          // Si falla el logo, intenta con la foto de portada.
        }
      }
    } finally {
      _loadingMarkerIcons.remove(restaurant.id);
    }
  }

  void _onMarkerTap(Restaurant r) {
    if (r.lat != null && r.lng != null) {
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(r.lat!, r.lng!), 16),
      );
    }
    _showRestaurantModal(r);
  }

  void _showRestaurantModal(Restaurant r) {
    setState(() => _selectedRestaurant = r);
    if (_mapsSupported &&
        !MediaQuery.disableAnimationsOf(context) &&
        r.lat != null &&
        r.lng != null) {
      _pinPulse.repeat();
    }
  }

  void _closeRestaurantModal() {
    _pinPulse.stop();
    setState(() => _selectedRestaurant = null);
  }

  static const String _cleanMapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';

  void _onMapCreated(GoogleMapController ctrl) {
    _mapCtrl = ctrl;
    _mapCtrl?.setMapStyle(_cleanMapStyle);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 72; // nav bar
    final restaurants = RestauranteScope.of(context).restaurants;

    final query = _searchQuery.trim().toLowerCase();

    final availableCuisines = restaurants
        .expand((r) => r.cuisines.isEmpty ? [r.cuisine] : r.cuisines)
        .toSet();
    final categories = Cuisine.values
        .where(availableCuisines.contains)
        .toList();

    final filteredRestaurants = restaurants.where((r) {
      if (_selectedCuisine != null &&
          !((r.cuisines.isEmpty ? [r.cuisine] : r.cuisines).contains(
            _selectedCuisine,
          ))) {
        return false;
      }
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.cuisineLabel.toLowerCase().contains(query) ||
          (r.address ?? r.zone).toLowerCase().contains(query);
    }).toList();

    final markers = <Marker>{};
    for (final r in filteredRestaurants) {
      if ((r.logoUrl ?? r.photoUrl)?.isNotEmpty == true) {
        _loadRestaurantMarkerIcon(r);
      }
      if (r.lat != null && r.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(r.id),
            position: LatLng(r.lat!, r.lng!),
            icon:
                _restaurantMarkerIcons[r.id] ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            anchor: const Offset(0.5, 0.5),
            onTap: () => _onMarkerTap(r),
          ),
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Mapa o fallback
        Positioned.fill(
          child: _mapsSupported
              ? AnimatedBuilder(
                  animation: _pinPulse,
                  builder: (context, _) {
                    final selected = _selectedRestaurant;
                    final showPulse =
                        selected?.lat != null &&
                        selected?.lng != null &&
                        !MediaQuery.disableAnimationsOf(context);
                    return GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: kInitialPosition,
                        zoom: 14,
                      ),
                      markers: markers,
                      circles: showPulse
                          ? {
                              Circle(
                                circleId: const CircleId('selected-restaurant'),
                                center: LatLng(selected!.lat!, selected.lng!),
                                radius: 12 + 30 * _pinPulse.value,
                                strokeColor: ConsumerColors.wine.withValues(
                                  alpha: 0.65 * (1 - _pinPulse.value),
                                ),
                                strokeWidth: 2,
                                fillColor: ConsumerColors.wine.withValues(
                                  alpha: 0.09 * (1 - _pinPulse.value),
                                ),
                              ),
                            }
                          : const {},
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      onMapCreated: _onMapCreated,
                    );
                  },
                )
              : FondoAlternativoMapa(),
        ),

        // ── UI flotante superior (solo barra de búsqueda + chips)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MapSearchBar(
                    onChanged: (q) {
                      setState(() {
                        _searchQuery = q;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FiltroCocinaMapa(
                          label: 'Todos',
                          icon: Icons.grid_view_rounded,
                          selected: _selectedCuisine == null,
                          onTap: () => setState(() => _selectedCuisine = null),
                        ),
                        ...categories.map(
                          (cuisine) => FiltroCocinaMapa(
                            label: cuisine.label,
                            icon: cuisine.icon,
                            selected: _selectedCuisine == cuisine,
                            onTap: () =>
                                setState(() => _selectedCuisine = cuisine),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Panel deslizable inferior con padding de nav bar
        if (_selectedRestaurant == null)
          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.14,
            maxChildSize: 0.88,
            builder: (_, ctrl) => Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: ListaRestaurantesMapa(
                ctrl: ctrl,
                restaurants: filteredRestaurants,
                onCardTap: _onMarkerTap,
              ),
            ),
          ),

        // Tarjeta de selección integrada: mantiene el mapa visible y evita el scrim oscuro.
        if (_selectedRestaurant != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad + 8,
            child: ModalRestauranteMapa(
              restaurant: _selectedRestaurant!,
              onClose: _closeRestaurantModal,
            ),
          ),
      ],
    );
  }
}
