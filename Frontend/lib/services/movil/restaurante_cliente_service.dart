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

    String? photoUrl;
    if (json['fotoPortada'] != null) {
      photoUrl = json['fotoPortada'].toString().startsWith('http')
          ? json['fotoPortada']
          : '${ApiConfig.baseUrl}${json['fotoPortada']}';
    }

    String? logoUrl;
    if (json['logo'] != null) {
      logoUrl = json['logo'].toString().startsWith('http')
          ? json['logo']
          : '${ApiConfig.baseUrl}${json['logo']}';
    }

    List<String> gallery = [];
    if (json['imagenes'] != null) {
      for (var img in json['imagenes']) {
        if (img['url'] != null) {
           gallery.add(img['url'].toString().startsWith('http') 
              ? img['url'] 
              : '${ApiConfig.baseUrl}${img['url']}');
        }
      }
    }

    List<ScheduleDay> schedule = [];
    if (json['horarios'] != null) {
      for (var h in json['horarios']) {
         schedule.add(ScheduleDay(
           dayLabel: h['diaSemana'] ?? '',
           openTime: h['horaInicio'] ?? '',
           closeTime: h['horaFin'] ?? '',
         ));
      }
    }

    return Restaurant(
      id: json['id'].toString(),
      name: json['nombre'],
      zone: json['direccion'] ?? 'Tarija',
      cuisine: cuisine,
      rating: 0.0, // Ya no usamos Random, si no hay rating real ponemos 0
      reviewCount: 0,
      priceLevel: 1,
      tagline: json['descripcion'] ?? '',
      emoji: cuisine.icon == Icons.local_fire_department_rounded ? '🔥' : '🍽️',
      tags: [cuisine.label],
      waitMinutes: 0,
      isOpen: json['estado'] ?? false,
      gradient: [const Color(0xFF6E1F35), const Color(0xFF3A0E1D)], // Color fijo vino tinto en lugar de aleatorio
      photoUrl: photoUrl,
      logoUrl: logoUrl,
      gallery: gallery,
      lat: json['latitud'] != null ? double.tryParse(json['latitud'].toString()) : null,
      lng: json['longitud'] != null ? double.tryParse(json['longitud'].toString()) : null,
      address: json['direccion'],
      schedule: schedule,
    );
  }
}
