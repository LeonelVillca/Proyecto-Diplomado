import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/app_web.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';
import 'package:frontend/services/shared/secure_http.dart';
import 'package:frontend/services/shared/session_service.dart';
import 'package:google_fonts/google_fonts.dart';
// Solo para sustituir fuentes en tests de navegación, sin descargar archivos.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_test;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final family in ['Poppins', 'Piazzolla', 'Manrope'])
      for (final variant in [
        'Thin',
        'ExtraLight',
        'Light',
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
        'Black',
        'Italic',
        'BoldItalic',
      ])
        'test-fonts/$family-$variant.ttf',
  ];

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

String _jwt({int seconds = 3600}) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + seconds,
            'permisos': ['menu_reservas'],
          }),
        ),
      )
      .replaceAll('=', '');
  return 'test.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final stored = <String, String>{};

  setUp(() {
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map).cast<String, dynamic>();
          switch (call.method) {
            case 'read':
              return stored[args['key']];
            case 'write':
              stored[args['key']] = args['value'];
              return null;
            case 'delete':
              stored.remove(args['key']);
              return null;
            default:
              throw StateError('Operación no prevista: ${call.method}');
          }
        });
  });

  setUpAll(() async {
    // El almacenamiento nativo y las fuentes son dependencias simuladas.
    // AuthController, SessionHttp y Navigator son las implementaciones reales.
    GoogleFonts.config.allowRuntimeFetching = false;
    font_test.assetManifest = _FontManifest();
    final fallback = File(
      'assets/fonts/Karla-VariableFont_wght.ttf',
    ).readAsBytesSync();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key.startsWith('test-fonts/')) {
            return ByteData.sublistView(fallback);
          }
          for (final path in ['build/unit_test_assets/$key', key]) {
            final file = File(path);
            if (file.existsSync()) {
              return ByteData.sublistView(file.readAsBytesSync());
            }
          }
          return null;
        });
    for (final weight in FontWeight.values) {
      GoogleFonts.poppins(fontWeight: weight);
      GoogleFonts.piazzolla(fontWeight: weight);
      GoogleFonts.manrope(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    font_test.assetManifest = null;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    SessionHttp.tokenProvider = null;
    SessionHttp.onUnauthorized = null;
    font_test.assetManifest = null;
  });

  Future<AuthController> authenticated({
    int seconds = 3600,
    int renewalStatus = 200,
  }) async {
    final session = SessionService();
    await session.guardarToken(_jwt(seconds: seconds));
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/perfil')) {
        return http.Response(
          jsonEncode({
            'id': 1,
            'correo': 'revision@example.test',
            'roles': ['admin_restaurante'],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/auth/renovar')) {
        return http.Response(
          jsonEncode({'token': _jwt(seconds: 7200)}),
          renewalStatus,
        );
      }
      throw StateError('Petición de autenticación no prevista');
    });
    final auth = AuthController(session: session, httpClient: client);
    expect(await auth.restaurarSesion(), isTrue);
    return auth;
  }

  Future<void> pushProtected(WidgetTester tester, Widget child) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(MaterialPageRoute<void>(builder: (_) => child));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> assertInvalidated(
    WidgetTester tester,
    AuthController auth,
    Finder login,
  ) async {
    await SessionHttp.check(
      http.Response('{"message":"Unauthorized"}', 401).statusCode,
      auth.token,
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(auth.isAuthenticated, isFalse);
    expect(auth.token, isNull);
    expect(auth.roles, isEmpty);
    expect(auth.permisos, isEmpty);
    expect(await SessionService().obtenerToken(), isNull);
    expect(login, findsOneWidget);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);
    expect(await navigator.maybePop(), isFalse);
    await tester.pump();
    expect(login, findsOneWidget);
  }

  testWidgets('móvil: 401 limpia sesión y pila desde una pantalla protegida', (
    tester,
  ) async {
    final auth = await authenticated();
    await tester.pumpWidget(
      App(
        authController: auth,
        initialScreen: const Scaffold(body: Text('Inicio protegido')),
      ),
    );
    await pushProtected(
      tester,
      const Scaffold(body: Text('Reserva protegida')),
    );
    expect(find.text('Reserva protegida'), findsOneWidget);
    await assertInvalidated(tester, auth, find.byType(LoginScreen));
    expect(find.text('Reserva protegida'), findsNothing);
    expect(find.text('Inicio protegido'), findsNothing);
    await SessionService().guardarToken(_jwt());
    expect(await auth.restaurarSesion(), isTrue);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('web admin: 401 sale del dashboard y no permite volver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = await authenticated();
    await tester.pumpWidget(AppWeb(authController: auth));
    await tester.pump(const Duration(seconds: 1));
    await pushProtected(tester, const AdminRestauranteDashboard());
    expect(find.byType(AdminRestauranteDashboard), findsOneWidget);
    await assertInvalidated(tester, auth, find.byType(AdminLoginScreen));
    expect(find.byType(AdminRestauranteDashboard), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('renovación 401 termina en login y elimina el JWT', (
    tester,
  ) async {
    final auth = await authenticated(seconds: 120, renewalStatus: 401);
    await tester.pumpWidget(
      App(
        authController: auth,
        initialScreen: const Scaffold(body: Text('Protegida')),
      ),
    );
    expect(await auth.validToken(), isNull);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await SessionService().obtenerToken(), isNull);
    expect(auth.isAuthenticated, isFalse);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  test('renovación 200 conserva sesión y guarda JWT nuevo', () async {
    final auth = await authenticated(seconds: 120);
    final previous = auth.token;
    final renewed = await auth.validToken();
    expect(renewed, isNotNull);
    expect(renewed, isNot(previous));
    expect(auth.isAuthenticated, isTrue);
    expect(auth.sessionInvalidationVersion, 0);
    expect(await SessionService().obtenerToken(), renewed);
    auth.dispose();
  });

  test('401 de JWT anterior no invalida una sesión renovada', () async {
    final auth = await authenticated(seconds: 120);
    final previous = auth.token!;
    await auth.validToken();
    await SessionHttp.check(401, previous);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.token, isNot(previous));
    expect(auth.sessionInvalidationVersion, 0);
    auth.dispose();
  });
  testWidgets('401 durante restauración también abre login al montar la app', (
    tester,
  ) async {
    await SessionService().guardarToken(_jwt());
    final auth = AuthController(
      httpClient: MockClient((_) async => http.Response('{}', 401)),
    );
    expect(await auth.restaurarSesion(), isFalse);
    expect(auth.sessionInvalidationVersion, 1);
    await tester.pumpWidget(
      App(
        authController: auth,
        initialScreen: const Scaffold(body: Text('Pantalla inicial')),
      ),
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await SessionService().obtenerToken(), isNull);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator).first).canPop(),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('500 no elimina sesión ni cambia la pantalla protegida', (
    tester,
  ) async {
    final auth = await authenticated();
    await tester.pumpWidget(
      App(
        authController: auth,
        initialScreen: const Scaffold(body: Text('Protegida')),
      ),
    );
    await SessionHttp.check(500, auth.token);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Protegida'), findsOneWidget);
    expect(auth.isAuthenticated, isTrue);
    expect(await SessionService().obtenerToken(), auth.token);
    expect(auth.sessionInvalidationVersion, 0);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
