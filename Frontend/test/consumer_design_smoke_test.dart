import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';
import 'package:frontend/screens/movil/reservations/reservation_sent_screen.dart';
import 'package:frontend/widgets/movil/navigation/app_bottom_nav.dart';

void main() {
  final restaurant = Restaurant(
    id: '1',
    name: 'Restaurante de prueba',
    zone: 'Centro',
    cuisine: Cuisine.tipico,
    rating: 0,
    reviewCount: 0,
    priceLevel: 1,
    tagline: '',
    emoji: '',
    tags: const [],
    waitMinutes: 0,
    isOpen: true,
    gradient: const [ConsumerColors.wine, ConsumerColors.wineDark],
  );

  testWidgets('la navegación muestra cuatro acciones y cambia la activa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(370, 790);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    HomeTab current = HomeTab.inicio;
    await tester.pumpWidget(
      MaterialApp(
        theme: ConsumerTheme.light,
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) => AppBottomNav(
              current: current,
              onSelected: (tab) => setState(() => current = tab),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('Reservas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    await tester.tap(find.text('Reservas'));
    await tester.pump();
    expect(current, HomeTab.reservas);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la solicitud muestra datos reales y su acción funciona', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(370, 790);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ConsumerTheme.light,
        home: Scaffold(
          body: Center(
            child: ReservationSentScreen(
              restaurant: restaurant,
              date: '25 de septiembre',
              time: '19:00',
              guests: 2,
              onMyReservations: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restaurante de prueba'), findsOneWidget);
    expect(find.text('25 de septiembre'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('pendiente de confirmación'), findsOneWidget);
    await tester.tap(find.text('Mis reservas'));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la confirmación se puede usar en horizontal', (tester) async {
    tester.view.physicalSize = const Size(790, 370);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ConsumerTheme.light,
        home: Scaffold(
          body: Center(
            child: ReservationSentScreen(
              restaurant: restaurant,
              date: '25 de septiembre',
              time: '19:00',
              guests: 2,
              onMyReservations: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mis reservas'));
    await tester.tap(find.text('Mis reservas'));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la confirmación se puede usar en horizontal', (tester) async {
    tester.view.physicalSize = const Size(790, 370);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ConsumerTheme.light,
        home: Scaffold(
          body: Center(
            child: ReservationSentScreen(
              restaurant: restaurant,
              date: '25 de septiembre',
              time: '19:00',
              guests: 2,
              onMyReservations: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mis reservas'));
    await tester.tap(find.text('Mis reservas'));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
