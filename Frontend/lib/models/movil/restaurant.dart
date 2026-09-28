import 'package:flutter/material.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

/// Tipos de cocina que se pueden encontrar en Tarija.
enum Cuisine {
  parrilla('Parrilla y churrasquería', Icons.local_fire_department_rounded, 'parrilla-churrasqueria'),
  vinoBar('Vino y Bar', Icons.wine_bar_rounded, 'vino-bar'),
  cafe('Cafetería y bistró', Icons.local_cafe_rounded, 'cafeteria-bistro'),
  tipico('Tarijeña o chapaca', Icons.soup_kitchen_rounded, 'tarijena-chapaca'),
  pizzeria('Pizzería', Icons.local_pizza_rounded, 'pizzeria'),
  pastas('Italiana', Icons.ramen_dining_rounded, 'italiana'),
  postres('Heladería y postres', Icons.icecream_rounded, 'heladeria-postres'),
  healthy('Vegetariana y comida natural', Icons.spa_rounded, 'vegetariana-natural'),
  boliviana('Comida boliviana', Icons.restaurant_rounded, 'boliviana'),
  pescados('Pescados y mariscos', Icons.set_meal_rounded, 'pescados-mariscos'),
  rapida('Comida rápida', Icons.fastfood_rounded, 'comida-rapida'),
  hamburguesas('Hamburguesas', Icons.lunch_dining_rounded, 'hamburguesas'),
  saltenas('Salteñería y empanadas', Icons.bakery_dining_rounded, 'saltenas-empanadas'),
  mexicana('Mexicana', Icons.local_dining_rounded, 'mexicana'),
  china('China', Icons.ramen_dining_rounded, 'china'),
  asiatica('Coreana y asiática', Icons.ramen_dining_rounded, 'coreana-asiatica'),
  peruana('Peruana', Icons.set_meal_rounded, 'peruana'),
  internacional('Internacional o fusión', Icons.public_rounded, 'internacional-fusion'),
  porDefinir('Por definir', Icons.help_outline_rounded, 'por-definir');

  const Cuisine(this.label, this.icon, this.slug);

  final String label;
  final IconData icon;
  final String slug;

  static Cuisine? fromSlug(String? slug) {
    for (final value in Cuisine.values) {
      if (value.slug == slug) return value;
    }
    return null;
  }
}

/// Restaurante de Mesa Chapaca.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.zone,
    required this.cuisine,
    this.cuisines = const [],
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
  final List<Cuisine> cuisines;
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

  String get cuisineLabel => (cuisines.isEmpty ? [cuisine] : cuisines)
      .map((item) => item.label)
      .join(' · ');
}
