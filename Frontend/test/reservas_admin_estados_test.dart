import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/reservas/gestion_reservas_screen.dart';
import 'package:frontend/services/shared/secure_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final accion in ['Confirmar', 'Rechazar']) {
    testWidgets(
      'RF-12: el panel conserva $accion y actualiza la reserva pendiente',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AuthController(
          httpClient: MockClient(
            (_) async => throw StateError('No se usa autenticación externa'),
          ),
        );
        // Identidad sin token de socket: toda la comunicación de este test es HTTP simulado.
        SessionHttp.tokenProvider = () async => 'sesion-ficticia';
        addTearDown(() {
          SessionHttp.tokenProvider = null;
          SessionHttp.onUnauthorized = null;
        });
        final fecha = DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10);
        var estado = 'pendiente';
        final cambios = <Map<String, dynamic>>[];
        var lecturas = 0;
        final clientFactory = () => MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path == '/api/v1/restaurante/mis-restaurantes') {
            return http.Response('[{"id":3}]', 200);
          }
          if (request.method == 'GET' &&
              request.url.path == '/api/v1/reservas/restaurante/3') {
            lecturas++;
            return http.Response(
              jsonEncode([
                {
                  'id': 9,
                  'estado': estado,
                  'fecha': fecha,
                  'hora': '16:00:00',
                  'numeroPersonas': 2,
                  'usuario': {'id': 26},
                  'mesa': {
                    'id': 2,
                    'numeroMesa': 'A1',
                    'restaurante': {'id': 3, 'nombre': 'Restaurante ficticio'},
                  },
                },
              ]),
              200,
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path == '/api/v1/reservas/9') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            cambios.add(body);
            estado = body['estado'] as String;
            return http.Response(jsonEncode({'id': 9, 'estado': estado}), 200);
          }
          throw StateError(
            'Solicitud no prevista: ${request.method} ${request.url.path}',
          );
        });
        try {
          await http.runWithClient(() async {
            await tester.pumpWidget(
              AuthScope(
                authController: auth,
                child: const MaterialApp(
                  home: Scaffold(body: GestionReservasScreen()),
                ),
              ),
            );
            // El indicador de pendiente anima continuamente; avanzar frames acotados.
            for (var frame = 0; frame < 20; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            expect(find.text('Confirmar'), findsOneWidget);
            expect(find.text('Rechazar'), findsOneWidget);
            await tester.ensureVisible(find.text(accion));
            await tester.tap(find.text(accion));
            for (var frame = 0; frame < 25; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            expect(cambios, [
              {'estado': accion == 'Confirmar' ? 'confirmada' : 'rechazada'},
            ]);
            expect(lecturas, 2);
            expect(find.text('Confirmar'), findsNothing);
            expect(find.text('Rechazar'), findsNothing);
            expect(
              find.text(accion == 'Confirmar' ? 'Confirmada' : 'Rechazada'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }, clientFactory);
        } finally {
          auth.dispose();
        }
      },
    );
  }
}
