import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/screens/movil/location/map_widgets.dart';
import 'package:frontend/models/movil/restaurant.dart';

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
  BitmapDescriptor? _customIcon;
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
    _initMarker();
  }

  @override
  void dispose() {
    _pinPulse.dispose();
    super.dispose();
  }

  Future<void> _initMarker() async {
    final int size = 96;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Sombra
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2.3, shadowPaint);

    // Pin blanco, más ligero y legible sobre el mapa.
    final Paint paint = Paint()..color = Colors.white;
    final Path pin = Path()
      ..moveTo(size / 2, size * .92)
      ..cubicTo(
        size * .72,
        size * .68,
        size * .80,
        size * .57,
        size * .80,
        size * .42,
      )
      ..cubicTo(
        size * .80,
        size * .18,
        size * .66,
        size * .08,
        size / 2,
        size * .08,
      )
      ..cubicTo(
        size * .34,
        size * .08,
        size * .20,
        size * .18,
        size * .20,
        size * .42,
      )
      ..cubicTo(
        size * .20,
        size * .57,
        size * .28,
        size * .68,
        size / 2,
        size * .92,
      )
      ..close();
    canvas.drawPath(pin, paint);

    final Paint innerPaint = Paint()..color = ConsumerColors.wine;
    canvas.drawCircle(Offset(size / 2, size * .39), size / 4.5, innerPaint);

    // Ícono central
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(LucideIcons.utensils.codePoint),
      style: TextStyle(
        fontSize: size / 2.5,
        fontFamily: LucideIcons.utensils.fontFamily,
        package: LucideIcons.utensils.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (mounted && byteData != null) {
      setState(() {
        _customIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      });
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

    final filteredRestaurants = restaurants.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.cuisine.label.toLowerCase().contains(query) ||
          (r.address ?? r.zone).toLowerCase().contains(query);
    }).toList();

    final markers = <Marker>{};
    for (final r in filteredRestaurants) {
      if (r.lat != null && r.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId(r.id),
            position: LatLng(r.lat!, r.lng!),
            icon:
                _customIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            onTap: () => _onMarkerTap(r),
          ),
        );
      }
    }

    return Stack(
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
              onCardTap: _onMarkerTap,
            ),
          ),
        ),

        // Tarjeta de selección integrada: mantiene el mapa visible y evita el scrim oscuro.
        if (_selectedRestaurant != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad - 16,
            child: _MapMarkerModal(
              restaurant: _selectedRestaurant!,
              onClose: _closeRestaurantModal,
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
      color: const Color(0xFFF2ECDF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.map, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              'Tarija · Bolivia',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'El mapa estará disponible en el dispositivo móvil',
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 12,
                color: Colors.black38,
              ),
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

  const _BottomSheet({
    required this.ctrl,
    required this.restaurants,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${restaurants.length} Restaurantes cerca',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
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
  const _MapMarkerModal({required this.restaurant, required this.onClose});

  final Restaurant restaurant;
  final VoidCallback onClose;

  void _goToDetails(BuildContext context) {
    onClose();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ConsumerColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CDBC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _RoundIconButton(
                      icon: LucideIcons.x,
                      onTap: onClose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 112,
                    height: 118,
                    child: restaurant.photoUrl == null
                        ? _placeholderImage()
                        : Image.network(
                            restaurant.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: ConsumerColors.ink,
                        ),
                      ),
                      if (restaurant.reviewCount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: ConsumerColors.gold,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ConsumerColors.ink,
                              ),
                            ),
                            Text(
                              ' (' + restaurant.reviewCount.toString() + ')',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ConsumerColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        restaurant.cuisine.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ConsumerColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _goToDetails(context),
                          child: const Text(
                            'Ver restaurante',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => const ColoredBox(
    color: ConsumerColors.paperDeep,
    child: Center(
      child: Icon(LucideIcons.utensils, size: 36, color: ConsumerColors.wine),
    ),
  );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withAlpha(235),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 18, color: ConsumerColors.ink),
      ),
    ),
  );
}
