import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/solicitud_admin_model.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error del servidor: ${res.statusCode}. Verifica los logs.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error actualizando estado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red),
        );
      }
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
                _buildInfoRow('NIT:', solicitud.nitNegocio ?? 'No provisto'),
                const SizedBox(height: 16),
                const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla')),
                const SizedBox(height: 4),
                Text(solicitud.descripcion ?? 'Sin descripción', style: const TextStyle(fontFamily: 'Karla')),
                const SizedBox(height: 16),
                if (solicitud.documentosAdjuntos != null && solicitud.documentosAdjuntos!.isNotEmpty)
                  const Text('Documentos:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Karla')),
                if (solicitud.documentosAdjuntos != null)
                  ...solicitud.documentosAdjuntos!.map((doc) => _buildDocumentoBoton(doc, solicitud.id)),
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

  Widget _buildDocumentoBoton(dynamic doc, int idSolicitud) {
    final tipo = doc['tipo'];
    final urlPath = doc['url']; // Ej: /privado/solicitudes/1/nit-uuid.pdf
    if (urlPath == null) return const SizedBox();

    final isPdf = urlPath.toString().toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: OutlinedButton.icon(
        icon: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: const Color(0xFF6B1A35)),
        label: Text('Ver Documento: $tipo', style: const TextStyle(color: Colors.black87)),
        onPressed: () => _abrirVisorDocumento(urlPath, tipo, isPdf),
      ),
    );
  }

  void _abrirVisorDocumento(String pathUrl, String tipo, bool isPdf) {
    if (isPdf && kIsWeb) {
      _abrirPdfNuevaPestana(pathUrl);
    } else {
      final currentToken = AuthScope.of(context).token ?? '';
      showDialog(
        context: context,
        builder: (ctx) => _VisorDocumentoDialog(
          pathUrl: pathUrl,
          tipo: tipo,
          isPdf: isPdf,
          token: currentToken,
        ),
      );
    }
  }

  Future<void> _abrirPdfNuevaPestana(String pathUrl) async {
    // Abrir la pestaña inmediatamente para evitar el bloqueo de popups
    final newWindow = html.window.open('', '_blank');

    try {
      final token = AuthScope.of(context).token ?? '';
      final parts = pathUrl.split('/');
      final filename = parts.last;
      final idSolicitud = parts[parts.length - 2];
      
      final fullUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/documento-adjunto/privado/$idSolicitud/$filename');

      final res = await http.get(fullUrl, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final blob = html.Blob([res.bodyBytes], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        
        if (newWindow != null) {
          // Redirigir la pestaña abierta al visor de PDF nativo del navegador
          newWindow.location.href = blobUrl;
        } else {
          // Fallback por si acaso
          html.window.open(blobUrl, '_blank');
        }
      } else {
        if (newWindow != null) {
          newWindow.close();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar el documento (${res.statusCode})'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (newWindow != null) {
        newWindow.close();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión de red al cargar el documento'), backgroundColor: Colors.red));
      }
    }
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

class _VisorDocumentoDialog extends StatefulWidget {
  final String pathUrl;
  final String tipo;
  final bool isPdf;
  final String token;

  const _VisorDocumentoDialog({
    required this.pathUrl,
    required this.tipo,
    required this.isPdf,
    required this.token,
  });

  @override
  State<_VisorDocumentoDialog> createState() => _VisorDocumentoDialogState();
}

class _VisorDocumentoDialogState extends State<_VisorDocumentoDialog> {
  bool _isLoading = true;
  Uint8List? _bytes;
  String? _blobUrl;
  String? _viewId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarArchivo();
  }

  Future<void> _cargarArchivo() async {
    try {
      final token = widget.token;
      // pathUrl viene como /privado/solicitudes/1/nit-uuid.pdf
      // Necesitamos armar la URL del backend correctamente.
      // En el backend la ruta es: GET /api/v1/documento-adjunto/privado/:idSolicitud/:filename
      // Pero el url guardado en base de datos es: /privado/solicitudes/{id}/{filename}
      // Entonces extraemos los parámetros del path guardado.
      final parts = widget.pathUrl.split('/');
      final filename = parts.last;
      final idSolicitud = parts[parts.length - 2];
      
      final fullUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/documento-adjunto/privado/$idSolicitud/$filename');

      final res = await http.get(fullUrl, headers: {
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bytes = res.bodyBytes;
            _isLoading = false;
            
            if (widget.isPdf && kIsWeb) {
              final blob = html.Blob([_bytes], 'application/pdf');
              _blobUrl = html.Url.createObjectUrlFromBlob(blob);
              _viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';
              
              // ignore: undefined_prefixed_name
              ui_web.platformViewRegistry.registerViewFactory(_viewId!, (int viewId) {
                final iframe = html.IFrameElement()
                  ..src = _blobUrl
                  ..style.border = 'none'
                  ..style.width = '100%'
                  ..style.height = '100%';
                return iframe;
              });
            }
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Error al cargar documento (${res.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _isLoading = false; });
      debugPrint('Error de conexion o parseo: $e');
    }
  }

  @override
  void dispose() {
    if (_blobUrl != null && kIsWeb) {
      html.Url.revokeObjectUrl(_blobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Documento: ${widget.tipo}', style: const TextStyle(fontFamily: 'BodoniModa', fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        height: 600,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _error != null 
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : widget.isPdf 
                    ? (kIsWeb && _viewId != null) 
                        ? HtmlElementView(viewType: _viewId!)
                        : const Center(child: Text('La visualización de PDF solo está soportada en Web.'))
                    : Image.memory(_bytes!, fit: BoxFit.contain),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
