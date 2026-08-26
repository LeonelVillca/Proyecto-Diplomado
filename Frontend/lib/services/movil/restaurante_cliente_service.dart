import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/movil/api_config.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class RestauranteClienteService {
  final String token;

  RestauranteClienteService(this.token);

  Future<List<Restaurant>> obtenerRestaurantes() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/restaurante'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => _mapToRestaurant(json)).toList();
    } else {
      throw Exception('Failed to load restaurants');
    }
  }

  Future<List<DishItem>> obtenerPlatosRestaurante(String restauranteId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/menu/restaurante/$restauranteId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> menus = jsonDecode(utf8.decode(response.bodyBytes));
      List<DishItem> dishes = [];
      for (var menu in menus) {
        if (menu['platos'] != null) {
          for (var plato in menu['platos']) {
            dishes.add(DishItem(
              id: plato['id'].toString(),
              name: plato['nombre'],
              price: (plato['precio'] as num).toDouble(),
              description: plato['descripcion'] ?? '',
              category: menu['nombre'], // Using menu name as category
              available: plato['disponible'] ?? true,
              photoUrl: plato['fotoUrl'] != null 
                  ? (plato['fotoUrl'].toString().startsWith('http') 
                      ? plato['fotoUrl'] 
                      : '${ApiConfig.baseUrl}${plato['fotoUrl']}') 
                  : null,
            ));
          }
        }
      }
      return dishes;
    } else {
      throw Exception('Failed to load menu dishes');
    }
  }

  Restaurant _mapToRestaurant(Map<String, dynamic> json) {
    // Generate some deterministic placeholder data for UI fields not in backend
    final random = Random(json['id']);
    
    Cuisine cuisine = Cuisine.tipico;
    if (json['tipoComida'] != null) {
      final tc = json['tipoComida'].toString().toLowerCase();
      if (tc.contains('parrilla') || tc.contains('carne')) cuisine = Cuisine.parrilla;
      else if (tc.contains('vino') || tc.contains('bar')) cuisine = Cuisine.vinoBar;
      else if (tc.contains('cafe') || tc.contains('café')) cuisine = Cuisine.cafe;
      else if (tc.contains('pizza')) cuisine = Cuisine.pizzeria;
      else if (tc.contains('pasta')) cuisine = Cuisine.pastas;
      else if (tc.contains('postre') || tc.contains('helado')) cuisine = Cuisine.postres;
      else if (tc.contains('sana') || tc.contains('healthy') || tc.contains('ensalada')) cuisine = Cuisine.healthy;
    }

    final gradients = [
      [const Color(0xFF6E1F35), const Color(0xFF3A0E1D)],
      [const Color(0xFFC97B3D), const Color(0xFF8E2F43)],
      [const Color(0xFF5C1A2E), const Color(0xFF8B6F3E)],
      [const Color(0xFF8B6F3E), const Color(0xFF4A6B4A)],
      [const Color(0xFF4A6B4A), const Color(0xFF2E4A33)],
      [const Color(0xFF7A5A2E), const Color(0xFF3A2A14)],
      [const Color(0xFF6E3B8E), const Color(0xFF2E3A5E)],
    ];

    return Restaurant(
      id: json['id'].toString(),
      name: json['nombre'],
      zone: json['direccion'] ?? 'Tarija',
      cuisine: cuisine,
      rating: 4.0 + random.nextDouble(), // Mock rating 4.0-5.0
      reviewCount: 50 + random.nextInt(400),
      priceLevel: 1 + random.nextInt(3),
      tagline: json['descripcion'] ?? 'Descubre los mejores sabores.',
      emoji: cuisine.icon == Icons.local_fire_department_rounded ? '🔥' : '🍽️',
      tags: [cuisine.label],
      waitMinutes: 10 + random.nextInt(20),
      isOpen: json['estado'] ?? false,
      gradient: gradients[json['id'] % gradients.length],
    );
  }
}
