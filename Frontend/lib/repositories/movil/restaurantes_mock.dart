import 'package:flutter/material.dart';

import 'package:frontend/models/movil/reservation.dart';
import 'package:frontend/models/movil/restaurant.dart';

/// Fuente de datos de restaurantes.
///
/// Por ahora usa datos de demostración. Cuando exista el backend, este archivo
/// se reemplaza por un repositorio HTTP sin tocar los widgets.
const List<Restaurant> mockRestaurants = [
  Restaurant(
    id: 'vino-luna',
    name: 'Vino y Luna',
    zone: 'Centro · Plaza Luis de Fuentes',
    cuisine: Cuisine.vinoBar,
    rating: 4.8,
    reviewCount: 312,
    priceLevel: 3,
    tagline: 'Maridajes y atardeceres en el corazón de Tarija.',
    emoji: '🍷',
    tags: ['Maridaje', 'Terraza'],
    waitMinutes: 20,
    isOpen: true,
    gradient: [Color(0xFF6E1F35), Color(0xFF3A0E1D)],
  ),
  Restaurant(
    id: 'la-ramona',
    name: 'La Ramona',
    zone: 'La Pampa · Av. Circunvalación',
    cuisine: Cuisine.tipico,
    rating: 4.7,
    reviewCount: 268,
    priceLevel: 2,
    tagline: 'Tradición chapaca con sazón de casa.',
    emoji: '🥟',
    tags: ['Cocina de autor', 'Casero'],
    waitMinutes: 15,
    isOpen: true,
    gradient: [Color(0xFFC97B3D), Color(0xFF8E2F43)],
  ),
  Restaurant(
    id: 'fogon-chapaco',
    name: 'El Fogón Chapaco',
    zone: 'San Jorge · Calle 25 de Mayo',
    cuisine: Cuisine.parrilla,
    rating: 4.9,
    reviewCount: 401,
    priceLevel: 3,
    tagline: 'Cortes nobles a la brasa y vinos del valle central.',
    emoji: '🔥',
    tags: ['Brasa', 'Reservas'],
    waitMinutes: 30,
    isOpen: true,
    gradient: [Color(0xFF5C1A2E), Color(0xFF8B6F3E)],
  ),
  Restaurant(
    id: 'casa-solar',
    name: 'Casa Solar',
    zone: 'Centro · Calle Ingavi',
    cuisine: Cuisine.pastas,
    rating: 4.6,
    reviewCount: 154,
    priceLevel: 2,
    tagline: 'Pastas frescas y pizza de horno de leña.',
    emoji: '🍝',
    tags: ['Horno de leña', 'Familiar'],
    waitMinutes: 10,
    isOpen: false,
    gradient: [Color(0xFF8B6F3E), Color(0xFF4A6B4A)],
  ),
  Restaurant(
    id: 'tinta-trigo',
    name: 'Tinta y Trigo',
    zone: 'San Roque · Diagonal',
    cuisine: Cuisine.healthy,
    rating: 4.5,
    reviewCount: 98,
    priceLevel: 2,
    tagline: 'Comida honesta, panadería y café de altura.',
    emoji: '🥗',
    tags: ['Healthy', 'Brunch'],
    waitMinutes: 8,
    isOpen: true,
    gradient: [Color(0xFF4A6B4A), Color(0xFF2E4A33)],
  ),
  Restaurant(
    id: 'milenario',
    name: 'Café Milenario',
    zone: 'La Florida · Plaza 15 de Abril',
    cuisine: Cuisine.cafe,
    rating: 4.7,
    reviewCount: 220,
    priceLevel: 1,
    tagline: 'Café de especialidad y dulces de temporada.',
    emoji: '☕',
    tags: ['Especialidad', 'Postres'],
    waitMinutes: 5,
    isOpen: true,
    gradient: [Color(0xFF7A5A2E), Color(0xFF3A2A14)],
  ),
  Restaurant(
    id: 'la-nana',
    name: 'La Naná',
    zone: 'Las Lomas · Camino a Cajas',
    cuisine: Cuisine.postres,
    rating: 4.6,
    reviewCount: 143,
    priceLevel: 1,
    tagline: 'Helados artesanales y queques de fin de semana.',
    emoji: '🍧',
    tags: ['Artesanal', 'Niños'],
    waitMinutes: 5,
    isOpen: true,
    gradient: [Color(0xFFC97B3D), Color(0xFF6E3B8E)],
  ),
  Restaurant(
    id: 'boulevard-15',
    name: 'Boulevard 15',
    zone: 'Centro · Av. 15 de Abril',
    cuisine: Cuisine.pizzeria,
    rating: 4.4,
    reviewCount: 176,
    priceLevel: 2,
    tagline: 'Pizzas napolitanas y música en vivo.',
    emoji: '🍕',
    tags: ['Música en vivo', 'Grupos'],
    waitMinutes: 25,
    isOpen: false,
    gradient: [Color(0xFF6E3B8E), Color(0xFF2E3A5E)],
  ),
];

/// Cuadros destacados del carrusel central.
class PromoSlide {
  const PromoSlide({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
}

const List<PromoSlide> mockPromos = [
  PromoSlide(
    label: 'Nosotres festejan',
    subtitle: 'Agrupa a tus amigos y reserven juntos con 15% de descuento.',
    icon: Icons.celebration_rounded,
    gradient: [Color(0xFFC97B3D), Color(0xFF5C1A2E)],
  ),
  PromoSlide(
    label: 'Atardecer Chapaco',
    subtitle: 'Terraza con vista al valle. Reserva tu mesa hoy.',
    icon: Icons.wb_twilight_rounded,
    gradient: [Color(0xFF5C1A2E), Color(0xFF2A0B17)],
  ),
  PromoSlide(
    label: 'Semana del Maridaje',
    subtitle: 'Renueva tu paladar con los vinos del valle central.',
    icon: Icons.wine_bar_rounded,
    gradient: [Color(0xFF4A6B4A), Color(0xFF8B6F3E)],
  ),
];

/// Zonas de Tarija para explorar.
class Zone {
  const Zone({required this.name, required this.emoji, required this.count});

  final String name;
  final String emoji;
  final int count;
}

const List<Zone> mockZones = [
  Zone(name: 'Centro', emoji: '🏛️', count: 18),
  Zone(name: 'La Pampa', emoji: '🌾', count: 12),
  Zone(name: 'San Jorge', emoji: '🌆', count: 9),
  Zone(name: 'San Roque', emoji: '⛪', count: 7),
  Zone(name: 'La Florida', emoji: '🌻', count: 11),
  Zone(name: 'Las Lomas', emoji: '⛰️', count: 6),
];

/// Reservas de demostración del usuario.
const List<Reservation> mockReservations = [
  Reservation(
    id: 'r1',
    restaurant: 'El Fogón Chapaco',
    zone: 'San Jorge · Calle 25 de Mayo',
    emoji: '🔥',
    date: 'Sáb 15 Ago',
    time: '20:30',
    guests: 4,
    upcoming: true,
  ),
  Reservation(
    id: 'r2',
    restaurant: 'Vino y Luna',
    zone: 'Centro · Plaza Luis de Fuentes',
    emoji: '🍷',
    date: 'Dom 16 Ago',
    time: '13:00',
    guests: 2,
    upcoming: true,
  ),
  Reservation(
    id: 'r3',
    restaurant: 'Café Milenario',
    zone: 'La Florida · Plaza 15 de Abril',
    emoji: '☕',
    date: 'Mar 11 Ago',
    time: '16:30',
    guests: 3,
    upcoming: false,
  ),
];