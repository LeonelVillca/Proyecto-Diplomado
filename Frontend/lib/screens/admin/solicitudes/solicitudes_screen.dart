import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/solicitud_admin_model.dart';
import 'package:universal_html/html.dart' as html;
import 'package:frontend/core/utils/web_helpers/platform_view_registry.dart' as ui_web;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/widgets/admin/admin_modal.dart';

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
    AdminModal.show(
      context: context,
      title: 'Detalle de Solicitud #${solicitud.id}',
      width: 700,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B635E),
            textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
          child: const Text('Cerrar'),
        ),
        if (solicitud.estado == 'pendiente') ...[
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstadoSolicitud(solicitud, 'rechazada');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text('Rechazar', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstadoSolicitud(solicitud, 'aprobada');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E1E39),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x336E1E39),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text('Aprobar Solicitud', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado Actual:',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildBadge(solicitud.estado.toUpperCase()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Restaurante', solicitud.nombreRestaurante),
                    const SizedBox(height: 16),
                    _buildDetailItem('Solicitante', '${solicitud.usuario?['nombre'] ?? ''} ${solicitud.usuario?['apellido'] ?? ''}'.trim()),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('NIT', solicitud.nitNegocio ?? 'No provisto'),
                    const SizedBox(height: 16),
                    _buildDetailItem('Teléfono', solicitud.celularContacto),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem('Correo Electrónico', '${solicitud.usuario?['correo'] ?? ''}'),
          const SizedBox(height: 24),
          Text('Descripción del Negocio', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFA39C98), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(solicitud.descripcion ?? 'Sin descripción proporcionada.', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1E1B1A), height: 1.5)),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Color(0xFFF0F2F5), height: 1),
          ),
          
          Text('Documentación Adjunta', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFA39C98), letterSpacing: 1)),
          const SizedBox(height: 12),
          if (solicitud.documentosAdjuntos != null && solicitud.documentosAdjuntos!.isNotEmpty)
            ...solicitud.documentosAdjuntos!.map((doc) => _buildDocumentoBoton(doc, solicitud.id))
          else
            Text('No hay documentos adjuntos.', style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    Color bg;
    Color fg;
    if (text == 'PENDIENTE') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (text == 'APROBADA') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF059669);
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Text(text, style: GoogleFonts.manrope(color: fg, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFA39C98), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E1B1A))),
      ],
    );
  }

  Widget _buildDocumentoBoton(dynamic doc, int idSolicitud) {
    final tipo = doc['tipo'];
    final urlPath = doc['url']; 
    if (urlPath == null) return const SizedBox();

    final isPdf = urlPath.toString().toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirVisorDocumento(urlPath, tipo, isPdf),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF0F2F5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: const Color(0xFFC9974F)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documento $tipo', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E1B1A))),
                      const SizedBox(height: 2),
                      Text(isPdf ? 'PDF' : 'Imagen', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFA39C98))),
                    ],
                  ),
                ),
                const Icon(Icons.remove_red_eye_outlined, color: Color(0xFFA39C98)),
              ],
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitudes de Restaurantes',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona y revisa las peticiones de nuevos negocios.',
          style: GoogleFonts.inter(color: const Color(0xFF6B635E), fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        // Filtros (Estilo Pestañas Píldora)
        Row(
          children: [
            _buildFilterTab('Pendientes', 'pendiente'),
            const SizedBox(width: 12),
            _buildFilterTab('Aprobadas', 'aprobada'),
            const SizedBox(width: 12),
            _buildFilterTab('Rechazadas', 'rechazada'),
          ],
        ),
        const SizedBox(height: 24),

        // Tabla / Lista de Tarjetas Flotantes
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
              : _solicitudes.isEmpty
                  ? Center(child: Text('No hay solicitudes en esta categoría', style: GoogleFonts.manrope(color: const Color(0xFFA39C98), fontSize: 15)))
                  : ListView.separated(
                      itemCount: _solicitudes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SolicitudCard(
                          solicitud: _solicitudes[index],
                          onTap: () => _verDetalles(_solicitudes[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String text, String estado) {
    final isSelected = _filtroEstado == estado;
    return InkWell(
      onTap: () {
        setState(() => _filtroEstado = estado);
        _cargarSolicitudes();
      },
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E1E39) : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF6E1E39) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x336E1E39), blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B635E),
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatefulWidget {
  final SolicitudAdminModel solicitud;
  final VoidCallback onTap;
  const _SolicitudCard({required this.solicitud, required this.onTap});

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final nombre = widget.solicitud.nombreRestaurante;
    final iniciales = nombre.length >= 2 ? nombre.substring(0, 2).toUpperCase() : nombre.toUpperCase();
    final solicitante = '${widget.solicitud.usuario?['nombre'] ?? ''} ${widget.solicitud.usuario?['apellido'] ?? ''}'.trim();
    final fecha = widget.solicitud.fechaSolicitud.split('T')[0];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: _hover ? 0.08 : 0.04),
              blurRadius: _hover ? 12 : 8,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: const Color(0xFFF0F2F5)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      iniciales,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF6E1E39),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: const Color(0xFF1E1B1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Color(0xFFA39C98)),
                            const SizedBox(width: 4),
                            Text(
                              solicitante.isNotEmpty ? solicitante : 'Sin nombre',
                              style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFA39C98)),
                            const SizedBox(width: 4),
                            Text(
                              fecha,
                              style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _hover ? const Color(0xFF6E1E39) : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Revisar detalles',
                      style: GoogleFonts.manrope(
                        color: _hover ? Colors.white : const Color(0xFF2D0A14),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    return AdminModal(
      title: 'Documento: ${widget.tipo}',
      width: 600,
      cancelText: 'Cerrar',
      confirmText: null, // Sin botón primario
      content: SizedBox(
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
    );
  }
}

