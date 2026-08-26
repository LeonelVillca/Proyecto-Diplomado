import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/repositories/movil/restaurantes_mock.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/widgets/movil/restaurant/favorite_heart.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/screens/movil/location/map_data.dart';
import 'package:frontend/screens/movil/location/map_widgets.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};

  // El mapa solo funciona en Web, Android e iOS.
  bool get _mapsSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    for (final r in mockMapRestaurants) {
      _markers.add(Marker(
        markerId: MarkerId(r.id),
        position: r.coords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(title: r.nombre, snippet: r.tipo),
        onTap: () => _onMarkerTap(r),
      ));
    }
  }

  void _onMarkerTap(MapRestaurant r) {
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(r.coords, 16));
    _showRestaurantModal(r);
  }

  void _showRestaurantModal(MapRestaurant r) {
    // Buscar en los restaurantes reales
    final restaurants = RestauranteScope.of(context, listen: false).restaurants;
    final realRestaurant = restaurants.firstWhere(
      (mock) => mock.id == r.id, 
      orElse: () => restaurants.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MapMarkerModal(
        mapRestaurant: r,
        fullRestaurant: realRestaurant,
      ),
    );
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

    return Stack(
      children: [
        // ── Mapa o fallback
        Positioned.fill(
          child: _mapsSupported
              ? GoogleMap(
                  initialCameraPosition: kInitialPosition,
                  markers: _markers,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: _onMapCreated,
                )
              : _MapFallback(),
        ),

        // ── UI flotante superior (solo barra de búsqueda + chips)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                MapSearchBar(),
                SizedBox(height: 10),
                MapFilterChips(),
              ],
            ),
          ),
        ),

        // ── Panel deslizable inferior con padding de nav bar
        DraggableScrollableSheet(
          initialChildSize: 0.18,
          minChildSize: 0.14,
          maxChildSize: 0.88,
          builder: (_, ctrl) => Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: _BottomSheet(ctrl: ctrl, onCardTap: _onMarkerTap),
          ),
        ),
      ],
    );
  }
}

// ── Fallback decorativo cuando Maps no soporta la plataforma ────────────────
class _MapFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E0D5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              'Tarija · Bolivia',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black45),
            ),
            const SizedBox(height: 6),
            Text(
              'El mapa estará disponible en el dispositivo móvil',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel inferior ───────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final ScrollController ctrl;
  final void Function(MapRestaurant) onCardTap;

  const _BottomSheet({required this.ctrl, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Column(
              children: [
                Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Text(
                  '${mockMapRestaurants.length} Restaurantes cerca',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: mockMapRestaurants.length,
              itemBuilder: (_, i) => RestaurantMapCard(
                restaurant: mockMapRestaurants[i],
                onTap: () => onCardTap(mockMapRestaurants[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal de Restaurante al tocar Marcador ──────────────────────────────────
class _MapMarkerModal extends StatelessWidget {
  const _MapMarkerModal({required this.mapRestaurant, required this.fullRestaurant});
  
  final MapRestaurant mapRestaurant;
  final dynamic fullRestaurant; // Es del tipo Restaurant

  void _goToDetails(BuildContext context) {
    Navigator.pop(context); // Cierra el modal primero
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: fullRestaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar SafeArea por si el dispositivo tiene gestos inferiores grandes
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _goToDetails(context),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ajusta la altura al contenido
              children: [
                // Foto de portada con boton favorito flotante
                Stack(
                  children: [
                    Image.asset(
                      'assets/restaurant_hero.png', // Placeholder (luego vendra de bd)
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FavoriteHeart(restaurantId: fullRestaurant.id),
                    ),
                  ],
                ),
                // Detalles de la tarjeta
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mapRestaurant.nombre,
                              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A0C12)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                mapRestaurant.rating.toString(),
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mapRestaurant.tipo} · ${mapRestaurant.precio}',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => _goToDetails(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6B1A35), // Color Vino
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Ver Restaurante',
                            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
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
    );
  }
}