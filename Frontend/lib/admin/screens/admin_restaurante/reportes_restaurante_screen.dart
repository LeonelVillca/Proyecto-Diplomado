import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_endpoints.dart';
import '../../../movil/providers/auth_provider.dart';

class ReportesRestauranteScreen extends StatefulWidget {
  const ReportesRestauranteScreen({super.key});

  @override
  State<ReportesRestauranteScreen> createState() => _ReportesRestauranteScreenState();
}

class _ReportesRestauranteScreenState extends State<ReportesRestauranteScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  
  int _totalReservas = 0;
  int _reservasPendientes = 0;
  int _reservasConfirmadas = 0;
  int _totalVisitas = 0;
  int _totalResenas = 0;
  double _promedioCalificacion = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatos();
      _isInit = false;
    }
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context).token;

      // 1. Obtener restaurante
      final urlRest = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final resRest = await http.get(urlRest, headers: {'Authorization': 'Bearer $token'});

      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(utf8.decode(resRest.bodyBytes));
        if (dataRest.isNotEmpty) {
          final int idRestaurante = dataRest.first['id'];
          
          // 2. Obtener reservas
          final urlReservas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$idRestaurante');
          final resReservas = await http.get(urlReservas, headers: {'Authorization': 'Bearer $token'});
          if (resReservas.statusCode == 200) {
            final List<dynamic> dataReservas = jsonDecode(utf8.decode(resReservas.bodyBytes));
            _totalReservas = dataReservas.length;
            _reservasPendientes = dataReservas.where((e) => e['estado'] == 'pendiente').length;
            _reservasConfirmadas = dataReservas.where((e) => e['estado'] == 'confirmada' || e['estado'] == 'completada').length;
          }

          // 3. Obtener reseñas
          final urlResenas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/restaurante/$idRestaurante');
          final resResenas = await http.get(urlResenas, headers: {'Authorization': 'Bearer $token'});
          if (resResenas.statusCode == 200) {
            final List<dynamic> dataResenas = jsonDecode(utf8.decode(resResenas.bodyBytes));
            _totalResenas = dataResenas.length;
            if (_totalResenas > 0) {
              final suma = dataResenas.fold<int>(0, (prev, curr) => prev + (curr['calificacion'] as int? ?? 0));
              _promedioCalificacion = suma / _totalResenas;
            }
          }

          // 4. Obtener visitas
          final urlVisitas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/visita/restaurante/$idRestaurante');
          final resVisitas = await http.get(urlVisitas, headers: {'Authorization': 'Bearer $token'});
          if (resVisitas.statusCode == 200) {
            final List<dynamic> dataVisitas = jsonDecode(utf8.decode(resVisitas.bodyBytes));
            _totalVisitas = dataVisitas.length;
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando reportes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reportes y Estadísticas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87)),
        const SizedBox(height: 8),
        Text('Métricas clave del rendimiento de tu restaurante.', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14)),
        const SizedBox(height: 32),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Visitas (Vistas)', _totalVisitas.toString(), Icons.visibility_outlined, Colors.blue),
                    _buildStatCard('Calificación Promedio', '${_promedioCalificacion.toStringAsFixed(1)} / 5.0', Icons.star_outline, Colors.amber),
                    _buildStatCard('Total Reseñas', _totalResenas.toString(), Icons.comment_outlined, Colors.purple),
                    _buildStatCard('Total Reservas', _totalReservas.toString(), Icons.calendar_today_outlined, Colors.teal),
                    _buildStatCard('Reservas Pendientes', _reservasPendientes.toString(), Icons.pending_actions, Colors.orange),
                    _buildStatCard('Reservas Confirmadas', _reservasConfirmadas.toString(), Icons.check_circle_outline, Colors.green),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Karla'))),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa')),
          ],
        ),
      ),
    );
  }
}
