import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/widgets/movil/restaurant/favorite_heart.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/screens/movil/location/map_widgets.dart';
import 'package:frontend/models/movil/restaurant.dart';

const LatLng kInitialPosition = LatLng(-21.5354, -64.7296);

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapCtrl;
  String _searchQuery = '';

  // El mapa solo funciona en Web, Android e iOS.
  bool get _mapsSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _onMarkerTap(Restaurant r) {
    if (r.lat != null && r.lng != null) {
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(r.lat!, r.lng!), 16));
    }
    _showRestaurantModal(r);
  }

  void _showRestaurantModal(Restaurant r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MapMarkerModal(
        restaurant: r,
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
    final restaurants = RestauranteScope.of(context).restaurants;
    
    final query = _searchQuery.trim().toLowerCase();
    
    final filteredRestaurants = restaurants.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
             r.cuisine.label.toLowerCase().contains(query) ||
             (r.address ?? r.zone).toLowerCase().contains(query);
    }).toList();

    final markers = <Marker>{};
    for (final r in filteredRestaurants) {
      if (r.lat != null && r.lng != null) {
        markers.add(Marker(
          markerId: MarkerId(r.id),
          position: LatLng(r.lat!, r.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: r.name, snippet: r.cuisine.label),
          onTap: () => _onMarkerTap(r),
        ));
      }
    }

    return Stack(
      children: [
        // ── Mapa o fallback
        Positioned.fill(
          child: _mapsSupported
              ? GoogleMap(
                  initialCameraPosition: const CameraPosition(target: kInitialPosition, zoom: 14),
                  markers: markers,
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
              children: [
                MapSearchBar(
                  onChanged: (q) {
                    setState(() {
                      _searchQuery = q;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const MapFilterChips(),
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
            child: _BottomSheet(
              ctrl: ctrl, 
              restaurants: filteredRestaurants,
              onCardTap: _onMarkerTap
            ),
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
            const Icon(Icons.map_outlined, size: 64, color: Colors.black26),
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
  final List<Restaurant> restaurants;
  final void Function(Restaurant) onCardTap;

  const _BottomSheet({required this.ctrl, required this.restaurants, required this.onCardTap});

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
                  '${restaurants.length} Restaurantes cerca',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: restaurants.length,
              itemBuilder: (_, i) => RestaurantMapCard(
                restaurant: restaurants[i],
                onTap: () => onCardTap(restaurants[i]),
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
  const _MapMarkerModal({required this.restaurant});
  
  final Restaurant restaurant;

  void _goToDetails(BuildContext context) {
    Navigator.pop(context); // Cierra el modal primero
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    if (restaurant.photoUrl != null)
                      Image.network(
                        restaurant.photoUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.black12,
                        child: const Icon(Icons.restaurant, size: 48, color: Colors.black26),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FavoriteHeart(restaurantId: restaurant.id),
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
                              restaurant.name,
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
                                restaurant.rating.toString(),
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${restaurant.cuisine.label} · ${restaurant.price}',
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