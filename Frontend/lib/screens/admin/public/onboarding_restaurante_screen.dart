import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class OnboardingRestauranteScreen extends StatefulWidget {
  final PerfilRestauranteModel restaurante;
  final VoidCallback onCompleted;

  const OnboardingRestauranteScreen({
    super.key,
    required this.restaurante,
    required this.onCompleted,
  });

  @override
  State<OnboardingRestauranteScreen> createState() => _OnboardingRestauranteScreenState();
}

class _OnboardingRestauranteScreenState extends State<OnboardingRestauranteScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoComidaCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;

  PlatformFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  PlatformFile? _selectedLogo;
  Uint8List? _selectedLogoBytes;

  List<PlatformFile> _selectedGallery = [];
  List<Uint8List> _selectedGalleryBytes = [];

  List<Map<String, dynamic>> _horarios = [];

  late TextEditingController _mesasTotalCtrl;
  late TextEditingController _capacidadTotalCtrl;

  // Paso 2
  late TextEditingController _direccionCtrl;
  late TextEditingController _horariosCtrl;

  GoogleMapController? _mapCtrl;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  bool get _mapsSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.restaurante.nombre);
    _tipoComidaCtrl = TextEditingController(text: widget.restaurante.tipoComida ?? '');
    _descripcionCtrl = TextEditingController(text: widget.restaurante.descripcion ?? '');
    _telefonoCtrl = TextEditingController(text: widget.restaurante.telefono ?? '');
    _correoCtrl = TextEditingController(text: widget.restaurante.correo ?? '');
    
    _direccionCtrl = TextEditingController();
    _mesasTotalCtrl = TextEditingController();
    _capacidadTotalCtrl = TextEditingController();
    _horariosCtrl = TextEditingController(text: '08:00 - 22:00');
  }

  @override
  void dispose() {
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
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) setState(() { _selectedImage = file; _selectedImageBytes = bytes; });
    }
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) setState(() { _selectedLogo = file; _selectedLogoBytes = bytes; });
    }
  }

  Future<void> _pickGallery() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: true, withData: true);
    if (result != null && result.files.isNotEmpty) {
      for(var file in result.files) {
         final bytes = file.bytes;
         if (bytes != null) setState(() { _selectedGallery.add(file); _selectedGalleryBytes.add(bytes); });
      }
    }
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _direccionCtrl.text = "Buscando dirección...";
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('restaurante_loc'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ));
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1');
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
          _direccionCtrl.text = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  Future<void> _abrirMapaModal() async {
    LatLng tempLoc = _selectedLocation ?? const LatLng(-21.5354, -64.7295);
    GoogleMapController? tempCtrl;
    final Set<Marker> tempMarkers = {
      if (_selectedLocation != null)
        Marker(
          markerId: const MarkerId('restaurante_loc_temp'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        )
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
                    initialCameraPosition: CameraPosition(target: tempLoc, zoom: 15),
                    markers: tempMarkers,
                    onMapCreated: (ctrl) => tempCtrl = ctrl,
                    onTap: (pos) {
                      setModalState(() {
                        tempLoc = pos;
                        tempMarkers.clear();
                        tempMarkers.add(Marker(
                          markerId: const MarkerId('restaurante_loc_temp'),
                          position: pos,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                        ));
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
    if (_selectedImage == null) {
      if (mounted) AdminNotificationModal.info(context, 'La foto de portada es obligatoria.');
      return;
    }
    if (_selectedLogoBytes == null) {
      if (mounted) AdminNotificationModal.info(context, 'El logo del restaurante es obligatorio.');
      return;
    }
    if (_horarios.isEmpty) {
      if (mounted) AdminNotificationModal.info(context, 'Debes configurar al menos un horario de atención.');
      return;
    }
    if (_mesasTotalCtrl.text.isEmpty || _capacidadTotalCtrl.text.isEmpty) {
      if (mounted) AdminNotificationModal.info(context, 'Configura la capacidad de tu salón (mesas y comensales).');
      return;
    }
    if (_selectedGallery.length < 5) {
      if (mounted) AdminNotificationModal.info(context, 'Sube al menos 5 fotografías en la galería.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}');
      final body = {
        'nombre': _nombreCtrl.text.trim(),
        'tipoComida': _tipoComidaCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'latitud': _selectedLocation?.latitude,
        'longitud': _selectedLocation?.longitude,
        'horarios': _horarios,
        'mesasTotal': int.tryParse(_mesasTotalCtrl.text),
        'capacidadTotal': int.tryParse(_capacidadTotalCtrl.text),
      };

      await http.patch(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (_selectedImageBytes != null) {
        final photoUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/portada');
        final photoReq = http.MultipartRequest('POST', photoUrl);
        photoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedImage!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
        photoReq.files.add(http.MultipartFile.fromBytes('file', _selectedImageBytes!, filename: _selectedImage!.name, contentType: MediaType('image', mimeType)));
        await photoReq.send();
      }

      if (_selectedLogoBytes != null) {
        final logoUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/logo');
        final logoReq = http.MultipartRequest('POST', logoUrl);
        logoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedLogo!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
        logoReq.files.add(http.MultipartFile.fromBytes('file', _selectedLogoBytes!, filename: _selectedLogo!.name, contentType: MediaType('image', mimeType)));
        await logoReq.send();
      }

      if (_selectedGalleryBytes.isNotEmpty) {
        final galeriaUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/galeria');
        final galReq = http.MultipartRequest('POST', galeriaUrl);
        galReq.headers['Authorization'] = 'Bearer $token';
        for (int i=0; i<_selectedGallery.length; i++) {
           final ext = _selectedGallery[i].name.split('.').last.toLowerCase();
           final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
           galReq.files.add(http.MultipartFile.fromBytes('files', _selectedGalleryBytes[i], filename: _selectedGallery[i].name, contentType: MediaType('image', mimeType)));
        }
        await galReq.send();
      }

      if (mounted) {
        AdminNotificationModal.success(context, '¡Perfil completado exitosamente!');
        widget.onCompleted();
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        AdminNotificationModal.error(context, 'Ocurrió un error al guardar el perfil.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: Container(
          width: 700,
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E1E39),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bienvenido a Mesa Chapaca', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A))),
                          Text('Completa el perfil de tu restaurante para comenzar.', style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stepper
              Expanded(
                child: Stepper(
                  type: StepperType.horizontal,
                  physics: const ClampingScrollPhysics(),
                  currentStep: _currentStep,
                  elevation: 0,
                  onStepContinue: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep += 1);
                    } else {
                      _finalizar();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: Text('Atrás', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF6B635E))),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isLoading ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E1E39),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_currentStep == 2 ? 'Guardar y Activar Restaurante' : 'Continuar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text('Identidad', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: _buildPaso1(),
                    ),
                    Step(
                      title: Text('Ubicación y Horarios', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                      content: _buildPaso2(),
                    ),
                    Step(
                      title: Text('Salón y Galería', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      isActive: _currentStep >= 2,
                      content: _buildPaso3(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Identidad Visual', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B1A))),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: Color(0xFFA39C98), size: 40),
                          const SizedBox(height: 8),
                          Text('Sube la foto de portada', style: GoogleFonts.manrope(color: const Color(0xFF6B635E))),
                        ],
                      ),
              ),
            ),
            Positioned(
              bottom: -40,
              child: InkWell(
                onTap: _pickLogo,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedLogoBytes != null
                    ? Image.memory(_selectedLogoBytes!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.add_a_photo, color: Color(0xFFA39C98), size: 30)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 50),
        Row(
          children: [
            Expanded(child: _buildTextField('Nombre del Restaurante', _nombreCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Tipo de Comida', _tipoComidaCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Descripción', _descripcionCtrl, maxLines: 3),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Teléfono', _telefonoCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Correo Público', _correoCtrl)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTextField('Dirección Extraída', _direccionCtrl),
        const SizedBox(height: 16),
        InkWell(
          onTap: _abrirMapaModal,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _mapsSupported
                    ? IgnorePointer(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(target: _selectedLocation ?? const LatLng(-21.5354, -64.7295), zoom: 15),
                          markers: _markers,
                          onMapCreated: (ctrl) => _mapCtrl = ctrl,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      )
                    : const Center(child: Text('Mapas no soportados en esta plataforma')),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fullscreen, color: Color(0xFF6E1E39), size: 18),
                      const SizedBox(width: 4),
                      Text('Expandir', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6E1E39))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Horarios de Atención', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B1A))),
        const SizedBox(height: 8),
        _buildHorariosBlock(),
      ],
    );
  }

  Widget _buildPaso3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Configuración de Salón', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B1A))),
        const SizedBox(height: 8),
        _buildMesasBlock(),
        const SizedBox(height: 24),
        Text('Galería de Fotos', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E1B1A))),
        const SizedBox(height: 8),
        _buildGaleriaBlock(),
      ],
    );
  }

  Widget _buildHorariosBlock() {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._horarios.asMap().entries.map((entry) {
          int idx = entry.key;
          var h = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: h['diaSemana'],
                    decoration: InputDecoration(isDense: true, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    items: dias.asMap().entries.map((d) => DropdownMenuItem(value: d.key, child: Text(d.value, style: GoogleFonts.manrope(fontSize: 14)))).toList(),
                    onChanged: (v) => setState(() => _horarios[idx]['diaSemana'] = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: h['horaInicio'],
                    decoration: InputDecoration(isDense: true, hintText: '00:00', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onChanged: (v) => _horarios[idx]['horaInicio'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: h['horaFin'],
                    decoration: InputDecoration(isDense: true, hintText: '23:59', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onChanged: (v) => _horarios[idx]['horaFin'] = v,
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _horarios.removeAt(idx))),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _horarios.add({'diaSemana': 0, 'horaInicio': '08:00', 'horaFin': '22:00'})),
          icon: const Icon(Icons.add, color: Color(0xFF6E1E39)),
          label: Text('Agregar Horario', style: GoogleFonts.manrope(color: const Color(0xFF6E1E39), fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildMesasBlock() {
    return Row(
      children: [
        Expanded(child: _buildTextField('Total de Mesas', _mesasTotalCtrl)),
        const SizedBox(width: 16),
        Expanded(child: _buildTextField('Capacidad Total (Comensales)', _capacidadTotalCtrl)),
      ],
    );
  }

  Widget _buildGaleriaBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFCF4F7), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6E1E39), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ðŸ“¸ Muestra lo mejor de tu ambiente y platillos: Sube al menos 5 fotografías de alta calidad para publicar tu restaurante ante los comensales.', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6E1E39)))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._selectedGalleryBytes.asMap().entries.map((e) => Stack(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(e.value, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: InkWell(
                    onTap: () => setState(() { _selectedGallery.removeAt(e.key); _selectedGalleryBytes.removeAt(e.key); }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                )
              ],
            )),
            InkWell(
              onTap: _pickGallery,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Center(child: Icon(Icons.add_photo_alternate, color: Color(0xFFA39C98), size: 32)),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6B635E))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6E1E39))),
          ),
        ),
      ],
    );
  }
}



