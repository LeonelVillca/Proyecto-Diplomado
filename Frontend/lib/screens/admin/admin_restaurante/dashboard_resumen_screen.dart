import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/widgets/admin/admin_ui.dart';

/// Resumen visual basado exclusivamente en los endpoints existentes de mesas
/// y reservas. No crea, modifica ni completa datos faltantes.
class DashboardResumenScreen extends StatefulWidget {
  const DashboardResumenScreen({super.key});

  @override
  State<DashboardResumenScreen> createState() => _DashboardResumenScreenState();
}

class _DashboardResumenScreenState extends State<DashboardResumenScreen> {
  bool _loading = true;
  bool _started = false;
  String? _restaurantName;
  List<Map<String, dynamic>> _mesas = [];
  List<Map<String, dynamic>> _reservas = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _cargarResumen();
    }
  }

  Future<void> _cargarResumen() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final headers = {'Authorization': 'Bearer $token'};
      final restauranteResponse = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes'),
        headers: headers,
      );
      if (restauranteResponse.statusCode != 200) return;

      final restaurantes = jsonDecode(utf8.decode(restauranteResponse.bodyBytes)) as List<dynamic>;
      if (restaurantes.isEmpty) return;
      final restaurante = Map<String, dynamic>.from(restaurantes.first as Map);
      final id = restaurante['id'];
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/restaurante/$id'), headers: headers),
        http.get(Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$id'), headers: headers),
      ]);
      final mesas = responses[0].statusCode == 200
          ? (jsonDecode(utf8.decode(responses[0].bodyBytes)) as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : <Map<String, dynamic>>[];
      final reservas = responses[1].statusCode == 200
          ? (jsonDecode(utf8.decode(responses[1].bodyBytes)) as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((item) => item['estado'] == 'pendiente' || item['estado'] == 'confirmada')
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _restaurantName = restaurante['nombre']?.toString();
        _mesas = mesas;
        _reservas = reservas;
      });
    } catch (_) {
      // El estado vacío deja claro que no hay información disponible.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _asInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final totalMesas = _mesas.length;
    final enUso = _mesas.where((mesa) => mesa['estado'] == 'ocupada' || mesa['estado'] == 'reservada').length;
    final capacidad = _mesas.fold<int>(0, (total, mesa) => total + _asInt(mesa['capacidad']));
    final comensales = _reservas.fold<int>(0, (total, reserva) => total + _asInt(reserva['numeroPersonas']));
    final porcentaje = totalMesas == 0 ? 0 : (enUso * 100 / totalMesas).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      children: [
        AdminPageHeader(
          kicker: 'OPERACIÓN',
          titleBefore: _restaurantName == null ? 'Resumen del ' : '',
          titleEmphasis: _restaurantName ?? 'restaurante',
          description: 'Consulta la disponibilidad de mesas y las reservas registradas.',
          actions: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _cargarResumen,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SummaryBanner(loading: _loading, reservations: _reservas.length, diners: comensales),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _MetricCard(icon: Icons.event_available_outlined, label: 'Reservas activas', value: _loading ? '—' : '${_reservas.length}', tint: AdminTheme.primaryLight, color: AdminTheme.primaryColor),
              _MetricCard(icon: Icons.groups_2_outlined, label: 'Comensales registrados', value: _loading ? '—' : '$comensales', tint: AdminTheme.accentSoft, color: AdminTheme.accentColor),
              _MetricCard(icon: Icons.table_restaurant_outlined, label: 'Mesas en uso', value: _loading ? '—' : '$enUso / $totalMesas', tint: AdminTheme.warningSoft, color: AdminTheme.warning),
              _MetricCard(icon: Icons.group_outlined, label: 'Capacidad registrada', value: _loading ? '—' : '$capacidad', tint: AdminTheme.successSoft, color: AdminTheme.success),
            ];
            if (constraints.maxWidth < 800) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards.map((card) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: card)).toList(),
              );
            }
            return Row(children: cards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: card))).toList());
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final salon = _SalonCard(loading: _loading, mesas: _mesas, porcentaje: porcentaje, enUso: enUso);
            final llegadas = _ArrivalsCard(loading: _loading, reservas: _reservas);
            if (constraints.maxWidth < 920) return Column(children: [salon, const SizedBox(height: 18), llegadas]);
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 5, child: salon), const SizedBox(width: 18), Expanded(flex: 4, child: llegadas)]),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.loading, required this.reservations, required this.diners});
  final bool loading;
  final int reservations;
  final int diners;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: AdminTheme.sidebar, borderRadius: AdminTheme.cardRadius, boxShadow: AdminTheme.shadowMd),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: AdminTheme.pillRadius),
              child: const Text('VISTA OPERATIVA', style: TextStyle(color: Color(0xFFFDF4EE), fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text('Todo el salón,\nen una sola vista.', style: TextStyle(fontFamily: 'Fraunces', fontSize: 28, height: 1.08, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 9),
            Text(loading ? 'Actualizando los datos del restaurante…' : '$reservations reservas activas para $diners comensales registrados.', style: const TextStyle(color: Color(0xD9FDF4EE), fontSize: 14, height: 1.45)),
          ])),
          const SizedBox(width: 24),
          Container(width: 66, height: 66, decoration: BoxDecoration(color: AdminTheme.primaryColor, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 30)),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.tint, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) => AdminSurface(
        padding: const EdgeInsets.all(18),
        radius: AdminTheme.mediumRadius,
        child: Row(children: [
          Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: AdminTheme.titleStyle.copyWith(fontSize: 22)), const SizedBox(height: 1), Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 12))])),
        ]),
      );
}

class _SalonCard extends StatelessWidget {
  const _SalonCard({required this.loading, required this.mesas, required this.porcentaje, required this.enUso});
  final bool loading;
  final List<Map<String, dynamic>> mesas;
  final int porcentaje;
  final int enUso;

  @override
  Widget build(BuildContext context) => AdminSurface(
        padding: const EdgeInsets.all(22),
        radius: AdminTheme.cardRadius,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Capacidad del salón', style: AdminTheme.titleStyle.copyWith(fontSize: 22)), const SizedBox(height: 3), Text('Estado actual de las mesas registradas.', style: AdminTheme.bodyStyle.copyWith(fontSize: 13))])),
            SizedBox(width: 58, height: 58, child: Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: loading ? 0.0 : porcentaje / 100, backgroundColor: AdminTheme.surfaceMuted, color: AdminTheme.primaryColor, strokeWidth: 7, strokeCap: StrokeCap.round), Center(child: Text(loading ? '—' : '$porcentaje%', style: AdminTheme.subtitleStyle.copyWith(fontSize: 12)))])),
          ]),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(color: AdminTheme.primaryColor)))
          else if (mesas.isEmpty)
            const _EmptyMessage(icon: Icons.table_restaurant_outlined, message: 'No hay mesas registradas todavía.')
          else
            Wrap(spacing: 10, runSpacing: 10, children: mesas.map((mesa) => _TableTile(mesa: mesa)).toList()),
          const SizedBox(height: 18),
          Text(loading ? '—' : '$enUso de ${mesas.length} mesas están ocupadas o reservadas.', style: AdminTheme.bodyStyle.copyWith(fontSize: 13)),
        ]),
      );
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.mesa});
  final Map<String, dynamic> mesa;

  @override
  Widget build(BuildContext context) {
    final estado = mesa['estado']?.toString() ?? 'libre';
    final active = estado == 'ocupada' || estado == 'reservada';
    final color = estado == 'ocupada' ? AdminTheme.primaryColor : estado == 'reservada' ? AdminTheme.warning : estado == 'inactiva' ? AdminTheme.textLight : AdminTheme.success;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(color: active ? color.withOpacity(.10) : AdminTheme.background, border: Border.all(color: active ? color.withOpacity(.30) : AdminTheme.border), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(mesa['numero_mesa']?.toString() ?? mesa['numeroMesa']?.toString() ?? 'Mesa', maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.subtitleStyle.copyWith(fontSize: 13)), const SizedBox(height: 4), Text(estado, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11))]),
    );
  }
}

class _ArrivalsCard extends StatelessWidget {
  const _ArrivalsCard({required this.loading, required this.reservas});
  final bool loading;
  final List<Map<String, dynamic>> reservas;

  @override
  Widget build(BuildContext context) => AdminSurface(
        padding: const EdgeInsets.all(22),
        radius: AdminTheme.cardRadius,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Próximas llegadas', style: AdminTheme.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 3),
          Text('Reservas pendientes y confirmadas.', style: AdminTheme.bodyStyle.copyWith(fontSize: 13)),
          const SizedBox(height: 17),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(color: AdminTheme.primaryColor)))
          else if (reservas.isEmpty)
            const _EmptyMessage(icon: Icons.event_busy_outlined, message: 'No hay próximas llegadas registradas.')
          else
            ...reservas.take(6).map((reserva) => _ArrivalRow(reserva: reserva)),
        ]),
      );
}

class _ArrivalRow extends StatelessWidget {
  const _ArrivalRow({required this.reserva});
  final Map<String, dynamic> reserva;

  @override
  Widget build(BuildContext context) {
    final usuario = reserva['usuario'] is Map ? Map<String, dynamic>.from(reserva['usuario'] as Map) : <String, dynamic>{};
    final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
    final estado = reserva['estado']?.toString() ?? 'pendiente';
    final confirmada = estado == 'confirmada';
    final color = confirmada ? AdminTheme.success : AdminTheme.warning;
    final mesa = reserva['mesa'] is Map ? Map<String, dynamic>.from(reserva['mesa'] as Map) : <String, dynamic>{};
    final hora = reserva['hora']?.toString() ?? 'Sin hora';
    final fecha = reserva['fecha']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminTheme.rowBorder))),
      child: Row(children: [
        AdminInitialAvatar(label: nombre.isEmpty ? 'Cliente' : nombre, round: true, size: 38),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(nombre.isEmpty ? 'Cliente sin nombre' : nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.subtitleStyle.copyWith(fontSize: 13)), const SizedBox(height: 2), Text('${mesa['numero_mesa'] ?? mesa['numeroMesa'] ?? 'Mesa no asignada'} · $hora${fecha.isEmpty ? '' : ' · $fecha'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminTheme.bodyStyle.copyWith(fontSize: 11.5))])),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: AdminTheme.pillRadius), child: Text(confirmada ? 'Confirmada' : 'Pendiente', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Column(children: [Icon(icon, color: AdminTheme.textLight, size: 30), const SizedBox(height: 9), Text(message, textAlign: TextAlign.center, style: AdminTheme.bodyStyle.copyWith(fontSize: 13))]),
      );
}
