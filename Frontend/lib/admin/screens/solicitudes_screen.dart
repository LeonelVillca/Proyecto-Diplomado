import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/solicitud_admin_model.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  String _filtroEstado = 'pendiente'; // pendiente, aprobado, rechazado
  bool _isLoading = true;
  List<SolicitudAdminModel> _solicitudes = [];

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarSolicitudes();
      _isInit = false;
    }
  }

  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/solicitud?estado=$_filtroEstado');
      
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _solicitudes = data.map((e) => SolicitudAdminModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando solicitudes: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cambiarEstadoSolicitud(SolicitudAdminModel solicitud, String nuevoEstado) async {
    try {
      final token = AuthScope.of(context).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/solicitud/${solicitud.id}');
      
      final body = {
        'estado': nuevoEstado,
      };

      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        _cargarSolicitudes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Solicitud marcada como $nuevoEstado')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error actualizando estado: $e');
    }
  }

  void _verDetalles(SolicitudAdminModel solicitud) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detalle de Solicitud #${solicitud.id}', style: const TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Restaurante:', solicitud.nombreRestaurante),
                _buildInfoRow('Teléfono:', solicitud.celularContacto),
                _buildInfoRow('Solicitante:', '${solicitud.usuario?['nombre']} ${solicitud.usuario?['apellido'] ?? ''}'),
                _buildInfoRow('Correo:', '${solicitud.usuario?['correo']}'),
                _buildInfoRow('Estado:', solicitud.estado.toUpperCase()),
                _buildInfoRow('Fecha:', solicitud.fechaSolicitud.split('T')[0]),
                const SizedBox(height: 16),
                const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla')),
                const SizedBox(height: 4),
                Text(solicitud.descripcion ?? 'Sin descripción', style: const TextStyle(fontFamily: 'Karla')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          if (solicitud.estado == 'pendiente') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _cambiarEstadoSolicitud(solicitud, 'rechazada');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _cambiarEstadoSolicitud(solicitud, 'aprobada');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Aprobar'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla'))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Karla'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solicitudes de Restaurantes',
          style: TextStyle(
            fontSize: 26, // Más pequeño y minimalista
            fontWeight: FontWeight.bold,
            fontFamily: 'BodoniModa',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona y revisa las peticiones de nuevos negocios.',
          style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        // Filtros (Estilo Pestañas Minimalistas)
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              _buildFilterTab('Pendientes', 'pendiente'),
              const SizedBox(width: 24),
              _buildFilterTab('Aprobadas', 'aprobada'),
              const SizedBox(width: 24),
              _buildFilterTab('Rechazadas', 'rechazada'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tabla
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _solicitudes.isEmpty
                  ? Center(child: Text('No hay solicitudes en esta categoría', style: TextStyle(fontFamily: 'Karla', color: Colors.grey.shade500, fontSize: 15)))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: _solicitudes.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final solicitud = _solicitudes[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            title: Text(
                              solicitud.nombreRestaurante,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Karla', fontSize: 15, color: Colors.black87),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${solicitud.usuario?['nombre']} • ${solicitud.fechaSolicitud.split('T')[0]}',
                                style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Karla', fontSize: 13),
                              ),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () => _verDetalles(solicitud),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B1A35),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                              child: const Text('Revisar', style: TextStyle(fontSize: 13, fontFamily: 'Karla', fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String text, String estado) {
    final isSelected = _filtroEstado == estado;
    return InkWell(
      onTap: () {
        setState(() {
          _filtroEstado = estado;
        });
        _cargarSolicitudes();
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF6B1A35) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF6B1A35) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
