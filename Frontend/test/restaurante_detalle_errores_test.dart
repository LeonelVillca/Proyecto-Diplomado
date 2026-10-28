import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/screens/movil/restaurantes/restaurant_detail_screen.dart';
import 'package:frontend/services/shared/secure_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Restaurant restaurante(String id) => Restaurant(
  id: id,
  name: 'Restaurante $id',
  zone: 'Tarija $id',
  cuisine: Cuisine.tipico,
  rating: 0,
  reviewCount: 0,
  priceLevel: 1,
  tagline: 'Descripción $id',
  emoji: '',
  tags: const [],
  waitMinutes: 0,
  isOpen: true,
  gradient: const [Colors.white, Colors.white],
);

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

List<Map<String, dynamic>> menus(String id) => [
  {
    'id': int.parse(id),
    'nombre': 'Menú $id',
    'restaurante': {'id': int.parse(id)},
    'platos': [
      {
        'id': int.parse(id),
        'nombre': 'Plato $id',
        'precio': 25,
        'disponible': true,
      },
    ],
  },
];

Future<void> avanzar(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> entorno(
  WidgetTester tester, {
  required Future<http.Response> Function(String id) menu,
  required Future<void> Function(
    ValueNotifier<Restaurant> seleccion,
    List<String> rutas,
  )
  comprobar,
  int catalogStatus = 200,
  Object? catalogError,
  List<int> ids = const [1, 2],
}) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SessionHttp.tokenProvider = () async => 'sesion-ficticia';
  addTearDown(() {
    SessionHttp.tokenProvider = null;
    SessionHttp.onUnauthorized = null;
  });
  final rutas = <String>[];
  await http.runWithClient(
    () async {
      final ctrl = RestauranteController('sesion-ficticia');
      final seleccion = ValueNotifier(restaurante('1'));
      try {
        await tester.pumpWidget(
          RestauranteScope(
            controller: ctrl,
            child: MaterialApp(
              theme: ConsumerTheme.light,
              home: ValueListenableBuilder<Restaurant>(
                valueListenable: seleccion,
                builder: (_, valor, _) =>
                    RestaurantDetailScreen(restaurant: valor),
              ),
            ),
          ),
        );
        await avanzar(tester);
        await comprobar(seleccion, rutas);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        seleccion.dispose();
        ctrl.dispose();
      }
    },
    () => MockClient((request) async {
      rutas.add(request.url.path);
      if (request.url.path == '/api/v1/restaurante') {
        if (catalogError != null) throw catalogError;
        return jsonResponse([
          for (final id in ids)
            {
              'id': id,
              'nombre': 'Restaurante $id',
              'descripcion': 'Descripción $id',
              'direccion': 'Tarija $id',
              'tipoComida': 'Típica',
              'estado': true,
            },
        ], catalogStatus);
      }
      if (request.url.path == '/api/v1/restaurante/ranking')
        return jsonResponse([]);
      final match = RegExp(
        r'^/api/v1/menu/restaurante/(\d+)$',
      ).firstMatch(request.url.path);
      if (match != null) return menu(match.group(1)!);
      if (request.url.path.startsWith('/api/v1/resenas/restaurante/'))
        return jsonResponse([]);
      throw StateError('Petición no prevista: ${request.url.path}');
    }),
  );
}

void main() {
  testWidgets(
    'RF-03/04: muestra restaurante y sus menús/platos sin repetir la consulta general',
    (tester) async {
      await entorno(
        tester,
        menu: (id) async => jsonResponse([
          ...menus(id),
          {
            'id': 10,
            'nombre': 'Segundo menú',
            'platos': [
              {'id': 10, 'nombre': 'Segundo plato', 'precio': 30},
            ],
          },
        ]),
        comprobar: (_, rutas) async {
          expect(find.text('Restaurante 1'), findsOneWidget);
          expect(find.text('Tarija 1'), findsOneWidget);
          expect(find.text('Menú 1'), findsOneWidget);
          expect(find.text('Plato 1'), findsOneWidget);
          expect(find.text('Segundo menú'), findsOneWidget);
          expect(find.text('Segundo plato'), findsOneWidget);
          expect(rutas.where((r) => r == '/api/v1/restaurante'), hasLength(1));
          expect(rutas.contains('/api/v1/restaurante/1'), isFalse);
        },
      );
    },
  );

  for (final sinPlatos in [false, true]) {
    testWidgets(
      'RF-04: consulta exitosa ${sinPlatos ? "con menú sin platos" : "sin menús"} muestra vacío',
      (tester) async {
        await entorno(
          tester,
          menu: (_) async => jsonResponse(
            sinPlatos
                ? [
                    {'nombre': 'Vacío', 'platos': []},
                  ]
                : [],
          ),
          comprobar: (_, _) async {
            expect(find.text('Menú no disponible'), findsOneWidget);
            expect(
              find.textContaining('No se pudieron recuperar'),
              findsNothing,
            );
          },
        );
      },
    );
  }

  testWidgets('RF-04: HTTP 500 de menús muestra error y no vacío', (
    tester,
  ) async {
    await entorno(
      tester,
      menu: (_) async => jsonResponse({'message': 'Fallo ficticio'}, 500),
      comprobar: (_, _) async {
        expect(
          find.textContaining('No se pudieron recuperar los menús y platos.'),
          findsOneWidget,
        );
        expect(find.text('Menú no disponible'), findsNothing);
      },
    );
  });

  for (final error in [
    http.ClientException('Conexión ficticia'),
    TimeoutException('Timeout ficticio'),
  ]) {
    testWidgets('RF-04: ${error.runtimeType} muestra error y no vacío', (
      tester,
    ) async {
      await entorno(
        tester,
        menu: (_) async => throw error,
        comprobar: (_, _) async {
          expect(
            find.textContaining('No se pudieron recuperar los menús y platos.'),
            findsOneWidget,
          );
          expect(find.text('Menú no disponible'), findsNothing);
        },
      );
    });
  }

  testWidgets(
    'RF-03: fallo de recuperación general no muestra datos del objeto recibido',
    (tester) async {
      await entorno(
        tester,
        catalogStatus: 500,
        menu: (id) async => jsonResponse(menus(id)),
        comprobar: (_, _) async {
          expect(
            find.textContaining(
              'No se pudo recuperar la información del restaurante.',
            ),
            findsOneWidget,
          );
          expect(find.text('Restaurante 1'), findsNothing);
          expect(find.text('Tarija 1'), findsNothing);
          expect(find.text('Plato 1'), findsNothing);
        },
      );
    },
  );

  for (final error in [
    http.ClientException('Sin conexión'),
    TimeoutException('Sin respuesta'),
  ]) {
    testWidgets('RF-03: ${error.runtimeType} de datos generales se informa', (
      tester,
    ) async {
      await entorno(
        tester,
        catalogError: error,
        menu: (_) async => jsonResponse([]),
        comprobar: (_, _) async {
          expect(
            find.textContaining(
              'No se pudo recuperar la información del restaurante.',
            ),
            findsOneWidget,
          );
          expect(find.text('Restaurante 1'), findsNothing);
        },
      );
    });
  }

  testWidgets(
    'RF-03: no sustituye un restaurante ausente por los datos de otro',
    (tester) async {
      await entorno(
        tester,
        ids: [2],
        menu: (_) async => jsonResponse([]),
        comprobar: (_, _) async {
          expect(
            find.text('La información de este restaurante no está disponible.'),
            findsOneWidget,
          );
          expect(find.text('Restaurante 1'), findsNothing);
          expect(find.text('Restaurante 2'), findsNothing);
        },
      );
    },
  );

  for (final falloTardio in [false, true]) {
    testWidgets(
      'RF-04: cambiar restaurante ignora ${falloTardio ? "error" : "menú"} tardío del anterior',
      (tester) async {
        final anterior = Completer<http.Response>();
        await entorno(
          tester,
          menu: (id) => id == '1'
              ? anterior.future
              : Future.value(jsonResponse(menus(id))),
          comprobar: (seleccion, rutas) async {
            seleccion.value = restaurante('2');
            await avanzar(tester);
            expect(find.text('Restaurante 2'), findsOneWidget);
            expect(find.text('Plato 2'), findsOneWidget);
            if (falloTardio)
              anterior.completeError(http.ClientException('Error anterior'));
            else
              anterior.complete(jsonResponse(menus('1')));
            await avanzar(tester);
            expect(find.text('Plato 2'), findsOneWidget);
            expect(find.text('Plato 1'), findsNothing);
            expect(
              find.textContaining('No se pudieron recuperar'),
              findsNothing,
            );
            expect(
              rutas,
              containsAll([
                '/api/v1/menu/restaurante/1',
                '/api/v1/menu/restaurante/2',
              ]),
            );
          },
        );
      },
    );
  }
}
