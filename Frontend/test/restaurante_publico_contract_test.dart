import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/services/movil/restaurante_cliente_service.dart';
import 'package:frontend/services/shared/secure_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final contrato = File(
    'test/fixtures/restaurante_publico.json',
  ).readAsStringSync();

  setUp(() {
    SessionHttp.tokenProvider = () async => 'sesion-ficticia';
  });
  tearDown(() {
    SessionHttp.tokenProvider = null;
    SessionHttp.onUnauthorized = null;
  });

  for (final ranking in [false, true]) {
    test(
      'interpreta ${ranking ? "ranking" : "catálogo"} sin solicitud y conserva los datos del detalle',
      () async {
        final restaurantes = await http.runWithClient(
          () {
            final servicio = RestauranteClienteService('sesion-ficticia');
            return ranking
                ? servicio.obtenerRanking()
                : servicio.obtenerRestaurantes();
          },
          () => MockClient((request) async {
            expect(request.method, 'GET');
            expect(
              request.url.path,
              ranking ? '/api/v1/restaurante/ranking' : '/api/v1/restaurante',
            );
            expect(request.headers['authorization'], 'Bearer sesion-ficticia');
            return http.Response(
              '[$contrato]',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

        final json = jsonDecode(contrato) as Map<String, dynamic>;
        expect(json.containsKey('solicitud'), isFalse);
        expect(restaurantes, hasLength(1));
        final restaurante = restaurantes.single;
        expect(restaurante.id, '21');
        expect(restaurante.name, 'Casa Tarija');
        expect(restaurante.cuisines, [Cuisine.tipico]);
        expect(restaurante.tagline, 'Comida local');
        expect(restaurante.phone, '70000000');
        expect(restaurante.address, 'Tarija 123');
        expect(restaurante.lat, -21.53);
        expect(restaurante.lng, -64.73);
        expect(restaurante.photoUrl, 'https://example.test/portada.webp');
        expect(restaurante.logoUrl, 'https://example.test/logo.webp');
        expect(restaurante.gallery, ['https://example.test/galeria.webp']);
        expect(restaurante.rating, 4.5);
        expect(restaurante.reviewCount, 2);
        expect(restaurante.isOpen, isTrue);
        expect(restaurante.schedule, hasLength(1));
        expect(restaurante.schedule.single.dayLabel, 'Lunes');
        expect(restaurante.schedule.single.openTime, '12:00');
        expect(restaurante.schedule.single.closeTime, '23:00');
      },
    );
  }
}
