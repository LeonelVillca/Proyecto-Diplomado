import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/screens/movil/reservations/reservation_screen.dart';
import 'package:frontend/widgets/movil/restaurant/detail_menu_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_info_tab.dart';
import 'package:frontend/widgets/movil/restaurant/detail_reviews_tab.dart';
import 'package:frontend/widgets/movil/restaurant/create_review_modal.dart';
import 'package:frontend/screens/movil/restaurantes/galeria_screen.dart';

part 'detalle_restaurante/servicio_detalle_restaurante.dart';
part 'detalle_restaurante/acciones_detalle_restaurante.dart';
part 'detalle_restaurante/resumen_restaurante_detalle.dart';
part '../../../widgets/movil/detalle_restaurante/portada_restaurante.dart';
part '../../../widgets/movil/detalle_restaurante/boton_redondo_detalle.dart';
part '../../../widgets/movil/detalle_restaurante/resumen_restaurante_detalle.dart';
part '../../../widgets/movil/detalle_restaurante/pestanas_detalle_restaurante.dart';
part '../../../widgets/movil/detalle_restaurante/barras_accion_restaurante.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  static const double _heroHeight = 325;
  static const double _summaryHeight = 174;
  static const double _summaryOverlap = 28;

  int _activeTab = 0;
  List<DishItem>? _dishes;
  List<ReviewItem>? _reviews;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPlatos();
      _cargarResenas();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openStatus = _obtenerEstadoApertura();
    return Scaffold(
      backgroundColor: ConsumerColors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: _heroHeight + _summaryHeight - _summaryOverlap,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _heroHeight,
                      child: PortadaRestaurante(restaurant: widget.restaurant),
                    ),
                    Positioned(
                      top: 10,
                      left: 8,
                      child: BotonRedondoDetalle(
                        icon: LucideIcons.arrowLeft,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: _heroHeight - _summaryOverlap,
                      left: 0,
                      right: 0,
                      child: _construirResumenRestaurante(context, openStatus),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: PestanasDetalleRestaurante(
                activeIndex: _activeTab,
                onChanged: _seleccionarPestana,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _activeTab == 0 ? 0 : 20,
                  14,
                  _activeTab == 0 ? 0 : 20,
                  20,
                ),
                child: KeyedSubtree(
                  key: ValueKey(_activeTab),
                  child: _construirContenidoPestana(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _activeTab == 2
          ? BarraResenasRestaurante(onTap: () => _mostrarCrearResena(context))
          : BarraReservaRestaurante(restaurant: widget.restaurant),
    );
  }
}
