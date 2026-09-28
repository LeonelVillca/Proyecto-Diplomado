import 'package:flutter/material.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

/// Tipos de cocina que se pueden encontrar en Tarija.
enum Cuisine {
  parrilla('Parrilla', Icons.local_fire_department_rounded),
  vinoBar('Vino y Bar', Icons.wine_bar_rounded),
  cafe('Café', Icons.local_cafe_rounded),
  tipico('Cocina típica', Icons.soup_kitchen_rounded),
  pizzeria('Pizzería', Icons.local_pizza_rounded),
  pastas('Pastas', Icons.ramen_dining_rounded),
  postres('Postres', Icons.icecream_rounded),
  healthy('Healthy', Icons.spa_rounded);

  const Cuisine(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Restaurante de Mesa Chapaca.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.zone,
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.tagline,
    required this.emoji,
    required this.tags,
    required this.waitMinutes,
    required this.isOpen,
    required this.gradient,
    this.photoUrl,
    this.logoUrl,
    this.gallery = const [],
    this.lat,
    this.lng,
    this.address,
    this.phone,
    this.schedule = const [],
  });

  final String id;
  final String name;
  final String zone;
  final Cuisine cuisine;
  final double rating;
  final int reviewCount;

  /// 1 = económico · 2 = medio · 3 = alto.
  final int priceLevel;
  final String tagline;
  final String emoji;
  final List<String> tags;
  final int waitMinutes;
  final bool isOpen;

  /// Degradado de portada (identidad visual de cada restaurante).
  final List<Color> gradient;

  // Nuevos campos del backend
  final String? photoUrl;
  final String? logoUrl;
  final List<String> gallery;
  final double? lat;
  final double? lng;
  final String? address;
  final String? phone;
  final List<ScheduleDay> schedule;

  /// Representación breve del precio: "$", "$$" o "$$$".
  String get price => List.filled(priceLevel, r'$').join();

  bool get isBestSeller => rating >= 4.7 && reviewCount >= 150;
}
