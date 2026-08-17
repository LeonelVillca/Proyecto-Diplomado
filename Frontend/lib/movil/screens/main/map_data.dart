import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Datos mock de un restaurante para el mapa.
class MapRestaurant {
  final String id;
  final String nombre;
  final String tipo;
  final double rating;
  final String precio;
  final LatLng coords;

  const MapRestaurant({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.rating,
    required this.precio,
    required this.coords,
  });
}

final List<MapRestaurant> mockMapRestaurants = [
  MapRestaurant(id: '1', nombre: 'La Casona Tarijeña', tipo: 'Tarijeña · Parrilla', rating: 4.8, precio: 'Bs 80–150', coords: const LatLng(-21.5311, -64.7294)),
  MapRestaurant(id: '2', nombre: 'El Viñedo del Sur', tipo: 'Italiana · Vinos', rating: 4.6, precio: 'Bs 100–200', coords: const LatLng(-21.5380, -64.7260)),
  MapRestaurant(id: '3', nombre: 'Rincón Criollo', tipo: 'Boliviana · Criolla', rating: 4.5, precio: 'Bs 50–100', coords: const LatLng(-21.5335, -64.7350)),
  MapRestaurant(id: '4', nombre: 'Café Jardín', tipo: 'Brunch · Café', rating: 4.7, precio: 'Bs 40–90', coords: const LatLng(-21.5290, -64.7320)),
  MapRestaurant(id: '5', nombre: 'La Taberna', tipo: 'Española · Tapas', rating: 4.4, precio: 'Bs 90–180', coords: const LatLng(-21.5420, -64.7230)),
];

const LatLng _tarija = LatLng(-21.5355, -64.7296);
const CameraPosition kInitialPosition = CameraPosition(target: _tarija, zoom: 14.2);

const kGoldColor = Color(0xFFD4AF37);
const kWineColor = Color(0xFF6B1A35);
