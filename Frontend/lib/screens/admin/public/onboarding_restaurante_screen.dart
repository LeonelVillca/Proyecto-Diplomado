import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/perfil_restaurante_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';

class OnboardingRestauranteScreen extends StatefulWidget {
  final PerfilRestauranteModel restaurante;
  final VoidCallback onCompleted;

  const OnboardingRestauranteScreen({
    super.key,
    required this.restaurante,
    required this.onCompleted,
  });

  @override
  State<OnboardingRestauranteScreen> createState() =>
      _OnboardingRestauranteScreenState();
}

class _OnboardingRestauranteScreenState
    extends State<OnboardingRestauranteScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _coverHovered = false;
  final ScrollController _contentScrollCtrl = ScrollController();
  List<Map<String, dynamic>> _catalogoTiposComida = [];
  final Set<int> _tiposComidaSeleccionados = {};

  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoComidaCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;

  PlatformFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  PlatformFile? _selectedLogo;
  Uint8List? _selectedLogoBytes;

  final List<PlatformFile> _selectedGallery = [];
  final List<Uint8List> _selectedGalleryBytes = [];

  final List<Map<String, dynamic>> _horarios = [];

  late TextEditingController _mesasTotalCtrl;
  late TextEditingController _capacidadTotalCtrl;

  // Paso 2
  late TextEditingController _direccionCtrl;
  late TextEditingController _horariosCtrl;

  GoogleMapController? _mapCtrl;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  bool get _mapsSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.restaurante.nombre);
    _tipoComidaCtrl = TextEditingController(
      text: widget.restaurante.tipoComida ?? '',
    );
    _descripcionCtrl = TextEditingController(
      text: widget.restaurante.descripcion ?? '',
    );
    _descripcionCtrl.addListener(_refreshDescription);
    _telefonoCtrl = TextEditingController(
      text: widget.restaurante.telefono ?? '',
    );
    _correoCtrl = TextEditingController(text: widget.restaurante.correo ?? '');

    _direccionCtrl = TextEditingController();
    _mesasTotalCtrl = TextEditingController();
    _capacidadTotalCtrl = TextEditingController();
    _horariosCtrl = TextEditingController(text: '08:00 - 22:00');
    _tiposComidaSeleccionados.addAll(
      widget.restaurante.tiposComida
          .map((tipo) => int.tryParse(tipo['id']?.toString() ?? ''))
          .whereType<int>(),
    );
    _cargarTiposComida();
  }

  void _refreshDescription() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarTiposComida() async {
    try {
      final token = AuthScope.of(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/tipos-comida'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(
          () => _catalogoTiposComida = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error cargando tipos de comida: $e');
    }
  }

  Widget _buildTiposComidaSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel('Tipos de comida', suffix: '· elige todos los que apliquen'),
      const SizedBox(height: 9),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: _catalogoTiposComida.map((tipo) {
          final id = int.tryParse(tipo['id']?.toString() ?? '');
          if (id == null) return const SizedBox.shrink();
          final isSelected = _tiposComidaSeleccionados.contains(id);
          return FilterChip(
            label: Text(tipo['nombre']?.toString() ?? ''),
            selected: isSelected,
            showCheckmark: true,
            checkmarkColor: AdminTheme.primaryColor,
            selectedColor: AdminTheme.primaryLight,
            backgroundColor: Colors.white,
            labelStyle: AdminTheme.bodyStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AdminTheme.primaryDark : AdminTheme.textMuted,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? AdminTheme.primaryColor : AdminTheme.border,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            onSelected: (selected) => setState(() {
              if (selected) {
                if (tipo['slug'] != 'por-definir') {
                  _tiposComidaSeleccionados.removeWhere(
                    (selectedId) => _catalogoTiposComida.any(
                      (entry) =>
                          entry['id'] == selectedId &&
                          entry['slug'] == 'por-definir',
                    ),
                  );
                } else {
                  _tiposComidaSeleccionados.clear();
                }
                _tiposComidaSeleccionados.add(id);
              } else {
                _tiposComidaSeleccionados.remove(id);
              }
            }),
          );
        }).toList(),
      ),
    ],
  );

  String _mensajeErrorApi(int statusCode, List<int> bodyBytes) {
    try {
      final body = jsonDecode(utf8.decode(bodyBytes));
      final message = body is Map ? body['message'] : null;
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join(', ');
    } catch (_) {
      // El servidor pudo responder un texto no JSON.
    }
    return 'El servidor rechazó la solicitud (HTTP $statusCode).';
  }

  Future<void> _verificarCarga(
    http.StreamedResponse response,
    String operacion,
  ) async {
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      await response.stream.drain<void>();
      return;
    }
    final bytes = await response.stream.toBytes();
    throw Exception(
      '$operacion: ${_mensajeErrorApi(response.statusCode, bytes)}',
    );
  }

  @override
  void dispose() {
    _contentScrollCtrl.dispose();
    _nombreCtrl.dispose();
    _tipoComidaCtrl.dispose();
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _mesasTotalCtrl.dispose();
    _capacidadTotalCtrl.dispose();
    _horariosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() {
          _selectedImage = file;
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() {
          _selectedLogo = file;
          _selectedLogoBytes = bytes;
        });
      }
    }
  }

  Future<void> _pickGallery() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        final bytes = file.bytes;
        if (bytes != null) {
          setState(() {
            _selectedGallery.add(file);
            _selectedGalleryBytes.add(bytes);
          });
        }
      }
    }
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _direccionCtrl.text = "Buscando dirección...";
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurante_loc'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['display_name'] != null) {
          final partes = data['display_name'].toString().split(',');
          final direccion = partes.take(2).join(',').trim();
          if (mounted) {
            setState(() {
              _direccionCtrl.text = direccion;
            });
          }
        } else {
          throw Exception('No results');
        }
      } else {
        throw Exception('HTTP Status ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
      if (mounted) {
        setState(() {
          _direccionCtrl.text =
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  Future<void> _abrirMapaModal() async {
    LatLng tempLoc = _selectedLocation ?? const LatLng(-21.5354, -64.7295);
    final Set<Marker> tempMarkers = {
      if (_selectedLocation != null)
        Marker(
          markerId: const MarkerId('restaurante_loc_temp'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
    };

    final LatLng? result = await AdminModal.show<LatLng>(
      context: context,
      title: 'Seleccionar Ubicación',
      width: 800,
      confirmText: 'Confirmar Ubicación',
      onConfirm: () => Navigator.pop(context, tempLoc),
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: 500,
            child: _mapsSupported
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: tempLoc,
                      zoom: 15,
                    ),
                    markers: tempMarkers,
                    onTap: (pos) {
                      setModalState(() {
                        tempLoc = pos;
                        tempMarkers.clear();
                        tempMarkers.add(
                          Marker(
                            markerId: const MarkerId('restaurante_loc_temp'),
                            position: pos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRose,
                            ),
                          ),
                        );
                      });
                    },
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    myLocationButtonEnabled: false,
                  )
                : const Center(child: Text('Mapas no soportados')),
          );
        },
      ),
    );

    if (result != null) {
      _onMapTapped(result);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(result, 15));
    }
  }

  Future<void> _finalizar() async {
    if (_tiposComidaSeleccionados.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Selecciona al menos un tipo de comida.',
        );
      }
      return;
    }
    if (_selectedImage == null) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'La foto de portada es obligatoria.',
        );
      }
      return;
    }
    if (_selectedLogoBytes == null) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'El logo del restaurante es obligatorio.',
        );
      }
      return;
    }
    if (_horarios.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Debes configurar al menos un horario de atención.',
        );
      }
      return;
    }
    if (_mesasTotalCtrl.text.isEmpty || _capacidadTotalCtrl.text.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Configura la capacidad de tu salón (mesas y comensales).',
        );
      }
      return;
    }
    final mesasTotal = int.tryParse(_mesasTotalCtrl.text.trim());
    final capacidadTotal = int.tryParse(_capacidadTotalCtrl.text.trim());
    if (mesasTotal == null ||
        capacidadTotal == null ||
        mesasTotal < 1 ||
        capacidadTotal < mesasTotal) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'La capacidad total debe ser un número igual o mayor que la cantidad de mesas.',
        );
      }
      return;
    }
    if (_selectedGallery.length < 5) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Te faltan ${5 - _selectedGallery.length} fotos para activar tu restaurante.',
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}',
      );
      final body = {
        'nombre': _nombreCtrl.text.trim(),
        'tiposComidaIds': _tiposComidaSeleccionados.toList(),
        'descripcion': _descripcionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'latitud': _selectedLocation?.latitude,
        'longitud': _selectedLocation?.longitude,
        'horarios': _horarios
            .map(
              (horario) => {
                'diaSemana': horario['diaSemana'],
                'horaInicio': horario['horaInicio'],
                'horaFin': horario['horaFin'],
              },
            )
            .toList(),
        'mesasTotal': mesasTotal,
        'capacidadTotal': capacidadTotal,
      };

      final patchResponse = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (patchResponse.statusCode != 200) {
        throw Exception(
          _mensajeErrorApi(patchResponse.statusCode, patchResponse.bodyBytes),
        );
      }

      if (_selectedImageBytes != null) {
        final photoUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/portada',
        );
        final photoReq = http.MultipartRequest('POST', photoUrl);
        photoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedImage!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'png'
            : (ext == 'webp' ? 'webp' : 'jpeg');
        photoReq.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedImageBytes!,
            filename: _selectedImage!.name,
            contentType: MediaType('image', mimeType),
          ),
        );
        await _verificarCarga(
          await photoReq.send(),
          'No se pudo guardar la portada',
        );
      }

      if (_selectedLogoBytes != null) {
        final logoUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/logo',
        );
        final logoReq = http.MultipartRequest('POST', logoUrl);
        logoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedLogo!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'png'
            : (ext == 'webp' ? 'webp' : 'jpeg');
        logoReq.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedLogoBytes!,
            filename: _selectedLogo!.name,
            contentType: MediaType('image', mimeType),
          ),
        );
        await _verificarCarga(
          await logoReq.send(),
          'No se pudo guardar el logo',
        );
      }

      if (_selectedGalleryBytes.isNotEmpty) {
        final galeriaUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/galeria',
        );
        final galReq = http.MultipartRequest('POST', galeriaUrl);
        galReq.headers['Authorization'] = 'Bearer $token';
        for (int i = 0; i < _selectedGallery.length; i++) {
          final ext = _selectedGallery[i].name.split('.').last.toLowerCase();
          final mimeType = ext == 'png'
              ? 'png'
              : (ext == 'webp' ? 'webp' : 'jpeg');
          galReq.files.add(
            http.MultipartFile.fromBytes(
              'files',
              _selectedGalleryBytes[i],
              filename: _selectedGallery[i].name,
              contentType: MediaType('image', mimeType),
            ),
          );
        }
        await _verificarCarga(
          await galReq.send(),
          'No se pudo guardar la galería',
        );
      }

      if (mounted) {
        AdminNotificationModal.success(
          context,
          '¡Perfil completado exitosamente!',
        );
        widget.onCompleted();
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        AdminNotificationModal.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.background,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final tablet = constraints.maxWidth <= 1080;
        final mobile = constraints.maxWidth <= 640;
        if (tablet) {
          return Column(
            children: [
              _progressPanel(compact: true),
              Expanded(child: _mainPane(mobile: mobile, tablet: true)),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 330, child: _progressPanel(compact: false)),
            Expanded(child: _mainPane(mobile: false, tablet: false)),
          ],
        );
      },
    ),
  );

  Widget _progressPanel({required bool compact}) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 17, 22, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF3ECDE),
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _brandMark(),
                const SizedBox(width: 9),
                Text(
                  'Mesa Chapaca',
                  style: AdminTheme.titleStyle.copyWith(fontSize: 18),
                ),
                const Spacer(),
                Text(
                  'PASO ${_currentStep + 1} DE 3',
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AdminTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _horizontalSteps(),
          ],
        ),
      );
    }
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFF3ECDE),
        border: Border(right: BorderSide(color: AdminTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _brandMark(),
              const SizedBox(width: 10),
              Text(
                'Mesa Chapaca',
                style: AdminTheme.titleStyle.copyWith(fontSize: 19),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 26),
          Text(
            'CONFIGURACIÓN INICIAL',
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido a\nMesa Chapaca',
            style: AdminTheme.titleStyle.copyWith(fontSize: 23, height: 1.18),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa el perfil de tu restaurante en 3 pasos y empieza a recibir reservas.',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 30),
          ...List.generate(3, _verticalStep),
          const Spacer(),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Progreso',
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentStep de 3',
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  color: AdminTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFE9E1D2)),
                  AnimatedFractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _currentStep / 3,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: Container(color: AdminTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandMark() => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AdminTheme.primaryColor,
      borderRadius: BorderRadius.circular(11),
    ),
    child: const Icon(LucideIcons.utensils, size: 17, color: Colors.white),
  );

  static const _stepNames = [
    'Identidad',
    'Ubicación y Horarios',
    'Salón y Galería',
  ];
  static const _stepDetails = [
    'Portada, nombre, tipos de comida y contacto.',
    'Dónde encontrarte y cuándo atender.',
    'Mesas, capacidad y tus mejores fotos.',
  ];

  Widget _stepCircle(int index) {
    final done = index < _currentStep;
    final active = index == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? AdminTheme.successSoft
            : active
            ? AdminTheme.primaryLight
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done
              ? Colors.transparent
              : active
              ? AdminTheme.primaryColor
              : const Color(0xFFD8CDBC),
          width: 1.5,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x29BE4B24),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: done
          ? const Icon(LucideIcons.check, size: 18, color: AdminTheme.success)
          : Text(
              '${index + 1}',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? AdminTheme.primaryDark : AdminTheme.textMuted,
              ),
            ),
    );
  }

  Widget _verticalStep(int index) {
    final done = index < _currentStep;
    final active = index == _currentStep;
    return SizedBox(
      height: index == 2 ? 80 : 105,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _stepCircle(index),
              if (index < 2)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: done
                        ? const Color(0xFFBFE3CE)
                        : const Color(0xFFE3DACA),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Opacity(
              opacity: index > _currentStep ? .55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'PASO ${index + 1}',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stepNames[index],
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AdminTheme.primaryDark
                          : AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stepDetails[index],
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalSteps() => Row(
    children: [
      for (var index = 0; index < 3; index++)
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : index <= _currentStep
                          ? const Color(0xFFBFE3CE)
                          : const Color(0xFFE3DACA),
                    ),
                  ),
                  _stepCircle(index),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 2
                          ? Colors.transparent
                          : index < _currentStep
                          ? const Color(0xFFBFE3CE)
                          : const Color(0xFFE3DACA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _stepNames[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: index == _currentStep
                      ? AdminTheme.primaryDark
                      : AdminTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _mainPane({required bool mobile, required bool tablet}) => Column(
    children: [
      Expanded(
        child: Scrollbar(
          controller: _contentScrollCtrl,
          child: SingleChildScrollView(
            controller: _contentScrollCtrl,
            padding: EdgeInsets.fromLTRB(
              tablet ? 22 : 56,
              tablet ? 30 : 44,
              tablet ? 22 : 56,
              30,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tablet ? 796 : 728),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _currentStep == 0
                        ? _buildPaso1(mobile)
                        : _currentStep == 1
                        ? _buildPaso2(mobile)
                        : _buildPaso3(mobile),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _footer(mobile),
    ],
  );

  void _continueStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      if (_contentScrollCtrl.hasClients) _contentScrollCtrl.jumpTo(0);
    } else {
      _finalizar();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      if (_contentScrollCtrl.hasClients) _contentScrollCtrl.jumpTo(0);
    }
  }

  Widget _footer(bool mobile) {
    final stacked = mobile || MediaQuery.sizeOf(context).width < 780;
    final primary = FilledButton.icon(
      onPressed: _isLoading ? null : _continueStep,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Icon(
              _currentStep == 2 ? LucideIcons.rocket : LucideIcons.arrowRight,
              size: 18,
            ),
      label: Text(
        _isLoading
            ? 'Activando...'
            : _currentStep == 2
            ? 'Guardar y Activar Restaurante'
            : 'Continuar',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AdminTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shadowColor: const Color(0x4DBE4B24),
        elevation: 5,
      ),
    );
    final back = TextButton.icon(
      onPressed: _currentStep == 0 || _isLoading ? null : _previousStep,
      icon: const Icon(LucideIcons.arrowLeft, size: 17),
      label: const Text('Atrás'),
      style: TextButton.styleFrom(foregroundColor: AdminTheme.textDark),
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(mobile ? 22 : 56, 15, mobile ? 22 : 56, 17),
      decoration: const BoxDecoration(
        color: AdminTheme.background,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: stacked
          ? Column(
              children: [
                SizedBox(width: double.infinity, child: primary),
                if (_currentStep > 0) back,
              ],
            )
          : Row(
              children: [
                if (_currentStep > 0) back else const SizedBox(width: 82),
                const Spacer(),
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: AdminTheme.gold,
                ),
                const SizedBox(width: 7),
                Text(
                  'Puedes editar todo esto después desde tu perfil',
                  style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                ),
                const Spacer(),
                primary,
              ],
            ),
    );
  }

  Widget _stepHeading(
    int index,
    String kicker,
    String before,
    String emphasis,
    String subtitle,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 9,
        children: [
          Container(width: 24, height: 2, color: AdminTheme.primaryColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'PASO ${index + 1} DE 3',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: AdminTheme.primaryDark,
              ),
            ),
          ),
          Text(
            kicker.toUpperCase(),
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AdminTheme.primaryColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      RichText(
        text: TextSpan(
          style: AdminTheme.titleStyle.copyWith(fontSize: 34),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: emphasis,
              style: AdminTheme.titleStyle.copyWith(
                fontSize: 34,
                color: AdminTheme.primaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: AdminTheme.bodyStyle.copyWith(fontSize: 15)),
      const SizedBox(height: 28),
    ],
  );

  Widget _sectionCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconBg,
    Color iconColor,
    Widget content,
  ) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AdminTheme.border),
      boxShadow: AdminTheme.shadowSm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AdminTheme.titleStyle.copyWith(fontSize: 19),
                  ),
                  Text(
                    subtitle,
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        content,
      ],
    ),
  );

  Widget _buildPaso1(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeading(
        0,
        'Identidad',
        'La primera impresión ',
        'se come con los ojos.',
        'Así verán tu restaurante los comensales por primera vez. Tómate tu tiempo con esto.',
      ),
      _sectionCard(
        'Foto de portada',
        'La imagen principal de tu perfil público.',
        LucideIcons.image,
        AdminTheme.primaryLight,
        AdminTheme.primaryColor,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _coverPicker(),
            const SizedBox(height: 22),
            const Divider(color: AdminTheme.rowBorder),
            const SizedBox(height: 16),
            _logoPicker(),
          ],
        ),
      ),
      _sectionCard(
        'Datos del restaurante',
        'Cómo se llama y qué se sirve en tu casa.',
        LucideIcons.store,
        AdminTheme.accentSoft,
        AdminTheme.accentColor,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              'Nombre del restaurante',
              _nombreCtrl,
              icon: LucideIcons.store,
              hint: 'ej. Casa Valcázar',
            ),
            const SizedBox(height: 18),
            _buildTiposComidaSelector(),
            const SizedBox(height: 18),
            _buildTextField(
              'Descripción',
              _descripcionCtrl,
              maxLines: 4,
              hint: 'Cuéntales tu historia',
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descripcionCtrl.text.length} / 300',
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _descripcionCtrl.text.length > 280
                      ? AdminTheme.warning
                      : AdminTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (mobile) ...[
              _buildTextField(
                'Teléfono / WhatsApp',
                _telefonoCtrl,
                icon: LucideIcons.phone,
                hint: 'ej. 65473914',
              ),
              const SizedBox(height: 18),
              _buildTextField(
                'Correo público',
                _correoCtrl,
                icon: LucideIcons.mail,
                hint: 'contacto@turestaurante.com',
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Teléfono / WhatsApp',
                      _telefonoCtrl,
                      icon: LucideIcons.phone,
                      hint: 'ej. 65473914',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Correo público',
                      _correoCtrl,
                      icon: LucideIcons.mail,
                      hint: 'contacto@turestaurante.com',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );

  Widget _coverPicker() => MouseRegion(
    onEnter: (_) => setState(() => _coverHovered = true),
    onExit: (_) => setState(() => _coverHovered = false),
    child: _selectedImageBytes == null
        ? InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              decoration: BoxDecoration(
                color: AdminTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD5C9B8), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AdminTheme.shadowSm,
                    ),
                    child: const Icon(
                      LucideIcons.cloudUpload,
                      size: 25,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Sube la foto de portada',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Haz clic aquí · JPG, PNG o WEBP',
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.successSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 13,
                            color: AdminTheme.success,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Portada cargada',
                            style: TextStyle(
                              color: AdminTheme.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    color: _coverHovered
                        ? const Color(0x661C1611)
                        : Colors.transparent,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity:
                          _coverHovered ||
                              MediaQuery.sizeOf(context).width <= 640
                          ? 1
                          : 0,
                      child: Wrap(
                        spacing: 10,
                        children: [
                          _coverAction(
                            LucideIcons.camera,
                            'Cambiar',
                            _pickImage,
                          ),
                          _coverAction(
                            LucideIcons.trash2,
                            'Quitar',
                            () => setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );

  Widget _coverAction(IconData icon, String label, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: label == 'Quitar'
              ? AdminTheme.error
              : AdminTheme.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
      );

  Widget _logoPicker() => Row(
    children: [
      InkWell(
        onTap: _pickLogo,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AdminTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminTheme.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedLogoBytes == null
              ? const Icon(
                  LucideIcons.image,
                  size: 25,
                  color: AdminTheme.primaryColor,
                )
              : Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logo del restaurante',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Necesario para activar tu perfil.',
              style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(LucideIcons.camera, size: 15),
              label: Text(
                _selectedLogoBytes == null ? 'Subir logo' : 'Cambiar logo',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AdminTheme.primaryColor,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildPaso2(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeading(
        1,
        'Ubicación y Horarios',
        'Que te encuentren ',
        'fácil.',
        'Tu punto exacto en el mapa y los horarios en los que esperas comensales.',
      ),
      _sectionCard(
        'Ubicación',
        'Selecciona tu restaurante en el mapa y confirma la dirección.',
        LucideIcons.mapPin,
        const Color(0xFFE8E8F5),
        const Color(0xFF4B4B8F),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _mapPicker(),
            const SizedBox(height: 16),
            _buildTextField(
              'Dirección extraída',
              _direccionCtrl,
              icon: LucideIcons.mapPin,
              hint: 'Aparece al seleccionar tu ubicación en el mapa',
            ),
          ],
        ),
      ),
      _sectionCard(
        'Horarios de atención',
        'Agrega los bloques de días y horas en que atiendes.',
        LucideIcons.clock,
        AdminTheme.warningSoft,
        AdminTheme.gold,
        _buildHorariosBlock(mobile),
      ),
    ],
  );

  Widget _mapPicker() => InkWell(
    onTap: _abrirMapaModal,
    borderRadius: BorderRadius.circular(18),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: _mapsSupported
                  ? IgnorePointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              _selectedLocation ??
                              const LatLng(-21.5354, -64.7295),
                          zoom: 15,
                        ),
                        markers: _markers,
                        onMapCreated: (ctrl) => _mapCtrl = ctrl,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF2ECDF),
                      alignment: Alignment.center,
                      child: const Text(
                        'Mapas no soportados en esta plataforma',
                      ),
                    ),
            ),
            Positioned(
              top: 14,
              left: 12,
              right: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedLocation == null
                        ? Colors.white.withValues(alpha: .94)
                        : AdminTheme.successSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedLocation == null
                          ? AdminTheme.border
                          : Colors.transparent,
                    ),
                    boxShadow: AdminTheme.shadowSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedLocation == null
                            ? LucideIcons.mapPin
                            : LucideIcons.check,
                        size: 15,
                        color: _selectedLocation == null
                            ? AdminTheme.primaryColor
                            : AdminTheme.success,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _selectedLocation == null
                              ? 'Haz clic en el mapa donde está tu restaurante'
                              : 'Ubicación seleccionada',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedLocation == null
                                ? AdminTheme.textDark
                                : AdminTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPaso3(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepHeading(
        2,
        'Salón y Galería',
        'Prepara tu ',
        'salón.',
        'Cuántos puedes atender por turno y las fotos que abren el apetito.',
      ),
      _sectionCard(
        'Configuración de salón',
        'Lo usaremos para gestionar la ocupación de tus reservas.',
        LucideIcons.armchair,
        AdminTheme.primaryLight,
        AdminTheme.primaryColor,
        _buildMesasBlock(mobile),
      ),
      _sectionCard(
        'Galería de fotos',
        'Ambiente, platos fuertes y la entrada del local.',
        LucideIcons.images,
        AdminTheme.warningSoft,
        AdminTheme.gold,
        _buildGaleriaBlock(),
      ),
    ],
  );

  Widget _buildHorariosBlock(bool mobile) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return Column(
      children: [
        for (final horario in _horarios) ...[
          if (_horarios.indexOf(horario) > 0) const SizedBox(height: 10),
          mobile
              ? Column(
                  children: [
                    _scheduleDay(horario, dias),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _scheduleTime(horario, 'horaInicio')),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—'),
                        ),
                        Expanded(child: _scheduleTime(horario, 'horaFin')),
                        const SizedBox(width: 7),
                        _scheduleRemove(horario),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _scheduleDay(horario, dias)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _scheduleTime(horario, 'horaInicio'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 9),
                      child: Text('—'),
                    ),
                    Expanded(flex: 2, child: _scheduleTime(horario, 'horaFin')),
                    const SizedBox(width: 10),
                    _scheduleRemove(horario),
                  ],
                ),
        ],
        if (_horarios.isNotEmpty) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(
              () => _horarios.add({
                'diaSemana': 0,
                'horaInicio': '08:00',
                'horaFin': '22:00',
              }),
            ),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Agregar horario'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.textMuted,
              side: const BorderSide(color: Color(0xFFD5C9B8), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scheduleDay(Map<String, dynamic> horario, List<String> dias) =>
      DropdownButtonFormField<int>(
        key: ValueKey((horario, 'day')),
        initialValue: horario['diaSemana'],
        isExpanded: true,
        style: AdminTheme.bodyStyle.copyWith(
          color: AdminTheme.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration(null).copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
        items: dias
            .asMap()
            .entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (value) => setState(() => horario['diaSemana'] = value!),
      );

  Widget _scheduleTime(Map<String, dynamic> horario, String field) =>
      TextFormField(
        key: ValueKey((horario, field)),
        initialValue: horario[field]?.toString() ?? '',
        textAlign: TextAlign.center,
        style: AdminTheme.bodyStyle.copyWith(
          color: AdminTheme.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration(null).copyWith(
          isDense: true,
          hintText: field == 'horaInicio' ? '00:00' : '23:59',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 13,
          ),
        ),
        onChanged: (value) => horario[field] = value,
      );

  Widget _scheduleRemove(Map<String, dynamic> horario) => SizedBox(
    width: 42,
    height: 42,
    child: IconButton(
      tooltip: 'Eliminar horario',
      onPressed: () => setState(() => _horarios.remove(horario)),
      icon: const Icon(LucideIcons.x, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.textMuted,
        side: const BorderSide(color: AdminTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );

  Widget _buildMesasBlock(bool mobile) {
    final tables = _salonCard(
      'TOTAL DE MESAS',
      LucideIcons.armchair,
      AdminTheme.primaryColor,
      AdminTheme.primaryLight,
      _mesasTotalCtrl,
      1,
    );
    final capacity = _salonCard(
      'CAPACIDAD TOTAL',
      LucideIcons.users,
      AdminTheme.accentColor,
      AdminTheme.accentSoft,
      _capacidadTotalCtrl,
      int.tryParse(_mesasTotalCtrl.text) ?? 1,
    );
    return mobile
        ? Column(children: [tables, const SizedBox(height: 16), capacity])
        : Row(
            children: [
              Expanded(child: tables),
              const SizedBox(width: 16),
              Expanded(child: capacity),
            ],
          );
  }

  Widget _salonCard(
    String label,
    IconData icon,
    Color iconColor,
    Color iconBg,
    TextEditingController controller,
    int min,
  ) {
    final value = int.tryParse(controller.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 23, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(
                  height: 43,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: AdminTheme.titleStyle.copyWith(fontSize: 30),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: '0',
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _salonStepButton(
                LucideIcons.plus,
                () => setState(() => controller.text = '${value + 1}'),
              ),
              const SizedBox(height: 6),
              _salonStepButton(
                LucideIcons.minus,
                value <= min
                    ? null
                    : () => setState(() => controller.text = '${value - 1}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _salonStepButton(IconData icon, VoidCallback? onPressed) => SizedBox(
    width: 34,
    height: 34,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.primaryColor,
        disabledForegroundColor: AdminTheme.textLight,
        side: const BorderSide(color: AdminTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
  );

  Widget _buildGaleriaBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 13,
        children: [
          SizedBox(
            width: 315,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, size: 16, color: AdminTheme.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sube al menos 5 fotos de alta calidad para activar tu perfil.',
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _galleryCount(),
        ],
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth <= 640 ? 3 : 5;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedGalleryBytes.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index == _selectedGalleryBytes.length) return _addPhotoTile();
              return _galleryPhoto(index);
            },
          );
        },
      ),
    ],
  );

  Widget _galleryCount() {
    final count = _selectedGalleryBytes.length;
    final done = count >= 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count de 5 fotos',
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textDark,
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            width: 130,
            height: 8,
            child: Stack(
              children: [
                Container(color: AdminTheme.rowBorder),
                AnimatedFractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (count / 5).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    color: done ? AdminTheme.success : AdminTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (done) ...[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.successSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.checkCheck,
                  size: 13,
                  color: AdminTheme.success,
                ),
                SizedBox(width: 4),
                Text(
                  '¡Listo!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _galleryPhoto(int index) {
    var hovered = false;
    return StatefulBuilder(
      builder: (context, localSetState) => MouseRegion(
        onEnter: (_) => localSetState(() => hovered = true),
        onExit: (_) => localSetState(() => hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: hovered ? 1.07 : 1,
                duration: const Duration(milliseconds: 400),
                child: Image.memory(
                  _selectedGalleryBytes[index],
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: hovered ? const Color(0x801C1611) : Colors.transparent,
              ),
              IgnorePointer(
                ignoring: !hovered && MediaQuery.sizeOf(context).width > 640,
                child: AnimatedOpacity(
                  opacity: hovered || MediaQuery.sizeOf(context).width <= 640
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Eliminar foto',
                          onPressed: () => setState(() {
                            _selectedGallery.removeAt(index);
                            _selectedGalleryBytes.removeAt(index);
                          }),
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: AdminTheme.error,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addPhotoTile() => InkWell(
    onTap: _pickGallery,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD5C9B8), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.plus,
            size: 23,
            color: AdminTheme.primaryColor,
          ),
          const SizedBox(height: 7),
          Text(
            'Añadir foto',
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminTheme.primaryColor,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _fieldLabel(String label, {String? suffix}) => RichText(
    text: TextSpan(
      style: AdminTheme.bodyStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AdminTheme.textDark,
      ),
      children: [
        TextSpan(text: label),
        if (suffix != null)
          TextSpan(
            text: '  $suffix',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
          ),
      ],
    ),
  );

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel(label),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: AdminTheme.bodyStyle.copyWith(
          fontSize: 14,
          color: AdminTheme.textDark,
        ),
        decoration: _inputDecoration(icon).copyWith(hintText: hint),
      ),
    ],
  );

  InputDecoration _inputDecoration(IconData? icon) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 17, color: AdminTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    hintStyle: AdminTheme.bodyStyle.copyWith(color: const Color(0xFFB8ADA2)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.border, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.primaryColor, width: 1.5),
    ),
  );
}
