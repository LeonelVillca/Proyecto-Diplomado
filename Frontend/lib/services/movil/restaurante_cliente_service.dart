import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/movil/api_config.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class ReservaFinalizadaRequerida implements Exception {
  const ReservaFinalizadaRequerida();

  @override
  String toString() =>
      'Podrás publicar tu reseña cuando tengas una reserva finalizada en este restaurante.';
}

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

  Future<List<Restaurant>> obtenerRanking() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/restaurante/ranking'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => _mapToRestaurant(json)).toList();
    } else {
      throw Exception('Failed to load ranking');
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
            dishes.add(
              DishItem(
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
              ),
            );
          }
        }
      }
      return dishes;
    } else {
      throw Exception('Failed to load menu dishes');
    }
  }

  Future<List<ReviewItem>> obtenerResenasRestaurante(
    String restauranteId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/resenas/restaurante/$restauranteId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      List<ReviewItem> reviews = [];
      for (var resena in data) {
        String nombre = resena['usuario']?['nombre'] ?? 'Usuario';
        String apellido = resena['usuario']?['apellido'] ?? '';
        String authorName = '$nombre $apellido'.trim();

        // Parse date relatively (e.g. "Hace 2 días") or just simple date
        DateTime? date = resena['fecha'] != null
            ? DateTime.tryParse(resena['fecha'])
            : null;
        String dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : 'Reciente';

        reviews.add(
          ReviewItem(
            id: resena['id'].toString(),
            authorName: authorName.isEmpty ? 'Anónimo' : authorName,
            rating: resena['calificacion'] ?? 0,
            comment: resena['comentario'] ?? '',
            date: dateStr,
            ownerReply: resena['respuesta']?['texto'],
          ),
        );
      }
      return reviews;
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<void> crearResena(
    String restauranteId,
    int idUsuario,
    int calificacion,
    String comentario,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/resenas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idRestaurante': int.parse(restauranteId),
        'idUsuario': idUsuario,
        'calificacion': calificacion,
        'comentario': comentario,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 400) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map &&
              body['message'] ==
                  'Solo puedes reseñar después de una reserva finalizada.') {
            throw const ReservaFinalizadaRequerida();
          }
        } on ReservaFinalizadaRequerida {
          rethrow;
        } on FormatException {
          // Mostrar el cuerpo original si la respuesta no es JSON.
        }
      }
      String message = 'No se pudo publicar la reseña.';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final apiMessage = body['message'];
        if (apiMessage is String && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
        if (apiMessage is List) {
          message = apiMessage.join(', ');
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<void> actualizarResena(
    String resenaId,
    int calificacion,
    String comentario,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/resenas/$resenaId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'calificacion': calificacion,
        'comentario': comentario,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo actualizar la reseña');
    }
  }

  Future<void> eliminarResena(String resenaId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/resenas/$resenaId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('No se pudo eliminar la reseña');
    }
  }

  Restaurant _mapToRestaurant(Map<String, dynamic> json) {
    final cuisines = <Cuisine>[];
    final rawCuisines = json['tiposComida'];
    if (rawCuisines is List) {
      for (final raw in rawCuisines) {
        if (raw is Map) {
          final cuisine = Cuisine.fromSlug(raw['slug']?.toString());
          if (cuisine != null && !cuisines.contains(cuisine)) {
            cuisines.add(cuisine);
          }
        }
      }
    }
    Cuisine cuisine = cuisines.isNotEmpty ? cuisines.first : Cuisine.tipico;
    if (json['tipoComida'] != null) {
      final tc = json['tipoComida'].toString().toLowerCase();
      if (cuisines.isEmpty && (tc.contains('hamburg') || tc.contains('burger')))
        cuisine = Cuisine.hamburguesas;
      else if (cuisines.isEmpty && (tc.contains('parrilla') || tc.contains('carne')))
        cuisine = Cuisine.parrilla;
      else if (cuisines.isEmpty && (tc.contains('vino') || tc.contains('bar')))
        cuisine = Cuisine.vinoBar;
      else if (cuisines.isEmpty && (tc.contains('cafe') || tc.contains('café')))
        cuisine = Cuisine.cafe;
      else if (cuisines.isEmpty && tc.contains('pizza'))
        cuisine = Cuisine.pizzeria;
      else if (cuisines.isEmpty && (tc.contains('pasta') || tc.contains('ital')))
        cuisine = Cuisine.pastas;
      else if (cuisines.isEmpty && (tc.contains('postre') || tc.contains('helado')))
        cuisine = Cuisine.postres;
      else if (cuisines.isEmpty && (tc.contains('sana') ||
          tc.contains('healthy') ||
          tc.contains('ensalada')))
        cuisine = Cuisine.healthy;
    }
    if (cuisines.isEmpty) cuisines.add(cuisine);

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
          gallery.add(
            img['url'].toString().startsWith('http')
                ? img['url']
                : '${ApiConfig.baseUrl}${img['url']}',
          );
        }
      }
    }

    String mapDiaSemana(dynamic dia) {
      if (dia == null) return '';
      final int? d = int.tryParse(dia.toString());
      switch (d) {
        case 0:
          return 'Lunes';
        case 1:
          return 'Martes';
        case 2:
          return 'Miércoles';
        case 3:
          return 'Jueves';
        case 4:
          return 'Viernes';
        case 5:
          return 'Sábado';
        case 6:
          return 'Domingo';
        default:
          return dia.toString();
      }
    }

    List<ScheduleDay> schedule = [];
    if (json['horarios'] != null) {
      for (var h in json['horarios']) {
        schedule.add(
          ScheduleDay(
            dayLabel: mapDiaSemana(h['diaSemana']),
            openTime: h['horaInicio'] ?? '',
            closeTime: h['horaFin'] ?? '',
          ),
        );
      }
    }

    return Restaurant(
      id: json['id'].toString(),
      name: json['nombre'] ?? 'Restaurante',
      cuisine: cuisine,
      cuisines: cuisines,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      priceLevel: 1,
      tagline: json['descripcion'] ?? '',
      zone: json['direccion'] ?? 'Zona Central',
      emoji: cuisine.icon == Icons.local_fire_department_rounded ? '🔥' : '🍽️',
      tags: [cuisine.label],
      waitMinutes: 0,
      isOpen: json['estado'] ?? false,
      gradient: [
        const Color(0xFF6E1F35),
        const Color(0xFF3A0E1D),
      ], // Color fijo vino tinto en lugar de aleatorio
      photoUrl: photoUrl,
      logoUrl: logoUrl,
      gallery: gallery,
      lat: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      lng: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
      address: json['direccion'],
      phone: json['telefono']?.toString(),
      schedule: schedule,
    );
  }
}
