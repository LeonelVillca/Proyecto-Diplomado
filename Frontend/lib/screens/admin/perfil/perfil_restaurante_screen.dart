import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/perfil_restaurante_model.dart';
import 'package:frontend/repositories/admin/restaurante_repository.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class PerfilRestauranteScreen extends StatefulWidget {
  const PerfilRestauranteScreen({super.key});

  @override
  State<PerfilRestauranteScreen> createState() => _PerfilRestauranteScreenState();
}

class _PerfilRestauranteScreenState extends State<PerfilRestauranteScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  bool _isSaving = false;
  PerfilRestauranteModel? _restaurante;
  final RestauranteRepository _repository = RestauranteRepository();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoComidaCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _direccionCtrl;

  PlatformFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  PlatformFile? _selectedLogo;
  Uint8List? _selectedLogoBytes;

  List<PlatformFile> _selectedGallery = [];
  List<Uint8List> _selectedGalleryBytes = [];
  List<String> _existingGalleryUrls = [];

  List<Map<String, dynamic>> _horarios = [];

  late TextEditingController _mesasTotalCtrl;
  late TextEditingController _capacidadTotalCtrl;

  GoogleMapController? _mapCtrl;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  bool get _mapsSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _tipoComidaCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _correoCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _mesasTotalCtrl = TextEditingController();
    _capacidadTotalCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarPerfil();
      _isInit = false;
    }
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
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context, listen: false).token;
      final restaurante = await _repository.obtenerMiRestaurante(token!);

      if (restaurante != null) {
        _restaurante = restaurante;
        _nombreCtrl.text = _restaurante!.nombre;
        _tipoComidaCtrl.text = _restaurante!.tipoComida ?? '';
        _descripcionCtrl.text = _restaurante!.descripcion ?? '';
        _telefonoCtrl.text = _restaurante!.telefono ?? '';
        _correoCtrl.text = _restaurante!.correo ?? '';
        _direccionCtrl.text = _restaurante!.direccion ?? '';
        
        if (_restaurante!.mesas != null && _restaurante!.mesas!.isNotEmpty) {
           _mesasTotalCtrl.text = _restaurante!.mesas!.length.toString();
           final cap = _restaurante!.mesas!.first['capacidad'] ?? 0;
           _capacidadTotalCtrl.text = (cap * _restaurante!.mesas!.length).toString();
        }
        if (_restaurante!.horarios != null) {
          _horarios = List<Map<String, dynamic>>.from(_restaurante!.horarios!);
        }
        if (_restaurante!.imagenes != null) {
          _existingGalleryUrls = _restaurante!.imagenes!.map((i) => i['url'].toString()).toList();
        }
        
        if (_restaurante!.latitud != null && _restaurante!.longitud != null) {
          _selectedLocation = LatLng(_restaurante!.latitud!, _restaurante!.longitud!);
          _actualizarMarcador(_selectedLocation!);
        } else {
          _selectedLocation = const LatLng(-21.5354, -64.7295); // Tarija por defecto
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil del restaurante: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      for(var file in result.files) {
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
      _actualizarMarcador(pos);
    });

    try {
      final direccion = await _repository.obtenerDireccionGeocoding(pos.latitude, pos.longitude);
      if (direccion != null && mounted) {
        setState(() {
          _direccionCtrl.text = direccion;
        });
      } else if (mounted) {
        setState(() {
          _direccionCtrl.text = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
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

  void _actualizarMarcador(LatLng pos) {
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('restaurante_loc'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    ));
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

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate() || _restaurante == null) return;

    if (_horarios.isEmpty) {
      if (mounted) AdminNotificationModal.info(context, 'Debes configurar al menos un horario de atención.');
      return;
    }

    if (_mesasTotalCtrl.text.isEmpty || _capacidadTotalCtrl.text.isEmpty) {
      if (mounted) AdminNotificationModal.info(context, 'Configura la capacidad de tu salón (mesas y comensales).');
      return;
    }

    if ((_existingGalleryUrls.length + _selectedGallery.length) < 5) {
      if (mounted) AdminNotificationModal.info(context, 'Sube al menos 5 fotografías en la galería.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      
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

      final exito = await _repository.actualizarPerfil(
        token: token!,
        restauranteId: _restaurante!.id,
        body: body,
        selectedImageBytes: _selectedImageBytes,
        selectedImage: _selectedImage,
        selectedLogoBytes: _selectedLogoBytes,
        selectedLogo: _selectedLogo,
        selectedGalleryBytes: _selectedGalleryBytes,
        selectedGallery: _selectedGallery,
      );

      if (exito) {
        if (mounted) {
          AdminNotificationModal.success(context, '¡Perfil actualizado con éxito!');
        }
      } else if (mounted) {
        AdminNotificationModal.error(context, 'No pudimos actualizar el perfil.');
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (mounted) AdminNotificationModal.error(context, 'Ocurrió un error inesperado.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor));
    }

    if (_restaurante == null) {
      return Center(child: Text('No tienes un restaurante asociado.', style: AdminTheme.bodyStyle));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              kicker: 'NEGOCIO',
              titleBefore: 'Perfil del ',
              titleEmphasis: 'Restaurante',
              description: 'Configura la información pública, ubicación y medios de tu restaurante.',
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Info General y Foto
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildBentoCard(
                        title: 'Identidad Visual (Portada y Logo)',
                        icon: Icons.image_outlined,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _selectedImageBytes != null
                                    ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                    : (_restaurante!.fotoPortada != null
                                        ? Image.network('${ApiEndpoints.baseUrl}${_restaurante!.fotoPortada}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                                        : _buildPlaceholder()),
                              ),
                            ),
                            Positioned(
                              bottom: -40,
                              child: InkWell(
                                onTap: _pickLogo,
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _selectedLogoBytes != null
                                    ? Image.memory(_selectedLogoBytes!, fit: BoxFit.cover)
                                    : (_restaurante!.logo != null
                                        ? Image.network('${ApiEndpoints.baseUrl}${_restaurante!.logo}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.store, color: Color(0xFFA39C98), size: 40)))
                                        : const Center(child: Icon(Icons.add_a_photo, color: Color(0xFFA39C98), size: 40))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildBentoCard(
                        title: 'Información Principal',
                        icon: Icons.storefront_outlined,
                        child: Column(
                          children: [
                            _buildTextField('Nombre del Restaurante', _nombreCtrl),
                            const SizedBox(height: 16),
                            _buildTextField('Tipo de Comida (Ej: Carnes, Vegetariano)', _tipoComidaCtrl),
                            const SizedBox(height: 16),
                            _buildTextField('Descripción / Historia', _descripcionCtrl, maxLines: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBentoCard(
                        title: 'Horarios de Atención',
                        icon: Icons.schedule_outlined,
                        child: _buildHorariosBlock(),
                      ),
                      const SizedBox(height: 24),
                      _buildBentoCard(
                        title: 'Configuración de Salón',
                        icon: Icons.table_restaurant_outlined,
                        child: _buildMesasBlock(),
                      ),
                      const SizedBox(height: 24),
                      _buildBentoCard(
                        title: 'Galería de Fotos',
                        icon: Icons.photo_library_outlined,
                        child: _buildGaleriaBlock(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Columna Derecha: Mapa, Contacto y Guardar
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildBentoCard(
                        title: 'Ubicación Exacta',
                        icon: Icons.map_outlined,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _abrirMapaModal,
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
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
                                        : Container(
                                            color: const Color(0xFFF8FAFC),
                                            child: const Center(child: Text('Mapas no soportados en esta plataforma')),
                                          ),
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
                            const SizedBox(height: 16),
                            _buildTextField('Calle / Dirección Extraída', _direccionCtrl),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBentoCard(
                        title: 'Contacto',
                        icon: Icons.contact_phone_outlined,
                        child: Column(
                          children: [
                            _buildTextField('Teléfono', _telefonoCtrl),
                            const SizedBox(height: 16),
                            _buildTextField('Correo Público', _correoCtrl),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardarPerfil,
                          icon: _isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_outlined),
                          label: Text('Guardar y Actualizar', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E1E39),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            elevation: 4,
                            shadowColor: const Color(0xFF6E1E39).withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, color: Color(0xFFA39C98), size: 40),
        const SizedBox(height: 8),
        Text('Haz clic para subir o cambiar foto', style: GoogleFonts.manrope(color: const Color(0xFF6B635E))),
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
            ..._existingGalleryUrls.map((url) => _buildGaleriaItem(networkUrl: url)),
            ..._selectedGalleryBytes.asMap().entries.map((e) => _buildGaleriaItem(bytes: e.value, index: e.key)),
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

  Widget _buildGaleriaItem({String? networkUrl, Uint8List? bytes, int? index}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: networkUrl != null 
             ? Image.network('${ApiEndpoints.baseUrl}$networkUrl', fit: BoxFit.cover)
             : Image.memory(bytes!, fit: BoxFit.cover),
        ),
        if (index != null)
          Positioned(
            top: 4, right: 4,
            child: InkWell(
              onTap: () => setState(() { _selectedGallery.removeAt(index); _selectedGalleryBytes.removeAt(index); }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildBentoCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: AdminTheme.cardRadius,
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AdminTheme.subtitleStyle),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminTheme.subtitleStyle.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark),
          decoration: AdminInputDecoration.get(labelText: label),
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }
}



