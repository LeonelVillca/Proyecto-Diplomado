import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  State<PerfilRestauranteScreen> createState() =>
      _PerfilRestauranteScreenState();
}

class _PerfilRestauranteScreenState extends State<PerfilRestauranteScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isInit = true;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _hydrating = false;
  bool _coverHovered = false;
  late final AnimationController _pulseController;
  PerfilRestauranteModel? _restaurante;
  final RestauranteRepository _repository = RestauranteRepository();
  List<Map<String, dynamic>> _catalogoTiposComida = [];
  final Set<int> _tiposComidaSeleccionados = {};

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
  List<Map<String, dynamic>> _existingGallery = [];
  final List<int> _deletedGalleryIds = [];

  List<Map<String, dynamic>> _horarios = [];

  late TextEditingController _mesasTotalCtrl;
  late TextEditingController _capacidadTotalCtrl;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _nombreCtrl = TextEditingController();
    _tipoComidaCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _correoCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _mesasTotalCtrl = TextEditingController();
    _capacidadTotalCtrl = TextEditingController();
    for (final controller in [
      _nombreCtrl,
      _descripcionCtrl,
      _telefonoCtrl,
      _correoCtrl,
      _direccionCtrl,
      _mesasTotalCtrl,
      _capacidadTotalCtrl,
    ]) {
      controller.addListener(_markDirty);
    }
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
    _pulseController.dispose();
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
    _hydrating = true;

    try {
      final token = AuthScope.of(context, listen: false).token;
      final restaurante = await _repository.obtenerMiRestaurante(token!);
      _catalogoTiposComida = await _repository.obtenerTiposComida(token);

      if (restaurante != null) {
        _restaurante = restaurante;
        _nombreCtrl.text = _restaurante!.nombre;
        _tipoComidaCtrl.text = _restaurante!.tipoComida ?? '';
        _tiposComidaSeleccionados
          ..clear()
          ..addAll(
            _restaurante!.tiposComida
                .map((tipo) => int.tryParse(tipo['id']?.toString() ?? ''))
                .whereType<int>(),
          );
        _descripcionCtrl.text = _restaurante!.descripcion ?? '';
        _telefonoCtrl.text = _restaurante!.telefono ?? '';
        _correoCtrl.text = _restaurante!.correo ?? '';
        _direccionCtrl.text = _restaurante!.direccion ?? '';

        if (_restaurante!.mesas != null && _restaurante!.mesas!.isNotEmpty) {
          _mesasTotalCtrl.text = _restaurante!.mesas!.length.toString();
          final cap = _restaurante!.mesas!.first['capacidad'] ?? 0;
          _capacidadTotalCtrl.text = (cap * _restaurante!.mesas!.length)
              .toString();
        }
        if (_restaurante!.horarios != null) {
          _horarios = List<Map<String, dynamic>>.from(_restaurante!.horarios!);
        }
        if (_restaurante!.imagenes != null) {
          _existingGallery = _restaurante!.imagenes!
              .whereType<Map>()
              .map((i) => Map<String, dynamic>.from(i))
              .toList();
        }

        if (_restaurante!.latitud != null && _restaurante!.longitud != null) {
          _selectedLocation = LatLng(
            _restaurante!.latitud!,
            _restaurante!.longitud!,
          );
          _actualizarMarcador(_selectedLocation!);
        } else {
          _selectedLocation = const LatLng(
            -21.5354,
            -64.7295,
          ); // Tarija por defecto
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil del restaurante: $e');
    } finally {
      _hydrating = false;
      _isDirty = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markDirty() {
    if (_hydrating || !mounted) return;
    setState(() => _isDirty = true);
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
          _isDirty = true;
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
          _isDirty = true;
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
            _isDirty = true;
          });
        }
      }
    }
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _isDirty = true;
      _direccionCtrl.text = "Buscando dirección...";
      _actualizarMarcador(pos);
    });

    try {
      final direccion = await _repository.obtenerDireccionGeocoding(
        pos.latitude,
        pos.longitude,
      );
      if (direccion != null && mounted) {
        setState(() {
          _direccionCtrl.text = direccion;
        });
      } else if (mounted) {
        setState(() {
          _direccionCtrl.text =
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
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

  void _actualizarMarcador(LatLng pos) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('restaurante_loc'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ),
    );
  }

  Widget _buildTiposComidaSelector() {
    if (_catalogoTiposComida.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No se pudieron cargar los tipos de comida.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tipos de comida',
            style: AdminTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Puedes elegir varios para que aparezcan en los filtros.',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _catalogoTiposComida.map((tipo) {
            final id = int.tryParse(tipo['id']?.toString() ?? '');
            if (id == null) return const SizedBox.shrink();
            final selected = _tiposComidaSeleccionados.contains(id);
            return FilterChip(
              label: Text(tipo['nombre']?.toString() ?? ''),
              selected: selected,
              showCheckmark: true,
              checkmarkColor: AdminTheme.primaryDark,
              selectedColor: AdminTheme.primaryLight,
              backgroundColor: Colors.white,
              labelStyle: AdminTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AdminTheme.primaryDark : AdminTheme.textMuted,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? AdminTheme.primaryColor : AdminTheme.border,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
              onSelected: (value) => setState(() {
                _isDirty = true;
                if (value) {
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

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate() || _restaurante == null) {
      return;
    }

    if (_tiposComidaSeleccionados.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Selecciona al menos un tipo de comida.',
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

    if ((_existingGallery.length + _selectedGallery.length) < 5) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Sube al menos 5 fotografías en la galería.',
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = AuthScope.of(context, listen: false).token;

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
        deletedImageIds: _deletedGalleryIds,
      );

      if (exito) {
        await _cargarPerfil();
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedLogo = null;
        _selectedLogoBytes = null;
        _selectedGallery = [];
        _selectedGalleryBytes = [];
        _deletedGalleryIds.clear();
        if (mounted) {
          AdminNotificationModal.success(
            context,
            '¡Perfil actualizado con éxito!',
          );
        }
      } else if (mounted) {
        AdminNotificationModal.error(
          context,
          'No pudimos actualizar el perfil.',
        );
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (mounted) {
        AdminNotificationModal.error(context, 'Ocurrió un error inesperado.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primaryColor),
      );
    }
    if (_restaurante == null) {
      return Center(
        child: Text(
          'No tienes un restaurante asociado.',
          style: AdminTheme.bodyStyle,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 720;
        final tablet = constraints.maxWidth <= 1080;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tablet ? 18 : 34,
                tablet ? 22 : 28,
                tablet ? 18 : 34,
                130,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (narrow) ...[
                          const AdminPageHeader(
                            kicker: 'CONFIGURACIÓN',
                            titleBefore: 'Perfil del ',
                            titleEmphasis: 'Restaurante.',
                            description:
                                'Todo lo que ven tus comensales antes de reservar en tu restaurante.',
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: _saveButton(),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: AdminPageHeader(
                                  kicker: 'CONFIGURACIÓN',
                                  titleBefore: 'Perfil del ',
                                  titleEmphasis: 'Restaurante.',
                                  description:
                                      'Todo lo que ven tus comensales antes de reservar en tu restaurante.',
                                ),
                              ),
                              const SizedBox(width: 20),
                              _saveButton(),
                            ],
                          ),
                        const SizedBox(height: 30),
                        _buildSection(
                          'Identidad visual',
                          'Tu primera impresión ante los comensales.',
                          LucideIcons.image,
                          AdminTheme.primaryLight,
                          AdminTheme.primaryColor,
                          _buildIdentity(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Información principal',
                          'Los datos que describen tu restaurante.',
                          LucideIcons.store,
                          AdminTheme.accentSoft,
                          AdminTheme.accentColor,
                          _buildInfo(narrow),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Ubicación exacta',
                          'Ayuda a tus comensales a encontrarte.',
                          LucideIcons.mapPin,
                          const Color(0xFFEFE9F6),
                          const Color(0xFF78628E),
                          _buildLocation(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Horarios de atención',
                          'Define cuándo pueden visitarte.',
                          LucideIcons.clock,
                          AdminTheme.warningSoft,
                          AdminTheme.gold,
                          _buildHorariosBlock(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Configuración de salón',
                          'Capacidad disponible para tus reservas.',
                          Icons.chair_outlined,
                          AdminTheme.primaryLight,
                          AdminTheme.primaryColor,
                          _buildMesasBlock(narrow),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Galería de fotos',
                          'Muestra tu ambiente y tus mejores platos.',
                          Icons.photo_library_outlined,
                          AdminTheme.warningSoft,
                          AdminTheme.gold,
                          _buildGaleriaBlock(),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: narrow
                              ? SizedBox(
                                  width: double.infinity,
                                  child: _saveButton(),
                                )
                              : _saveButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: !_isDirty,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  offset: _isDirty ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isDirty ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 470),
                        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: AdminTheme.textDark,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6626201A),
                              blurRadius: 50,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: Tween<double>(
                                begin: .35,
                                end: 1,
                              ).animate(_pulseController),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: AdminTheme.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Tienes cambios sin guardar',
                                style: AdminTheme.bodyStyle.copyWith(
                                  color: const Color(0xFFFDF8F1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            FilledButton(
                              onPressed: _isSaving ? null : _guardarPerfil,
                              style: FilledButton.styleFrom(
                                backgroundColor: AdminTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Guardar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _saveButton() => FilledButton.icon(
    onPressed: _isSaving ? null : _guardarPerfil,
    icon: _isSaving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : const Icon(LucideIcons.check, size: 18),
    label: Text(
      _isSaving ? 'Guardando...' : 'Guardar y actualizar',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: AdminTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shadowColor: const Color(0x47BE4B24),
      elevation: 5,
    ),
  );

  Widget _buildSection(
    String title,
    String subtitle,
    IconData icon,
    Color iconBackground,
    Color iconColor,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AdminTheme.titleStyle.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentity() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 266 : 250,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _coverHovered = true),
                  onExit: (_) => setState(() => _coverHovered = false),
                  child: SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_selectedImageBytes != null)
                            Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          else if (_restaurante!.fotoPortada != null)
                            Image.network(
                              _mediaUrl(_restaurante!.fotoPortada!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildCoverPlaceholder(),
                            )
                          else
                            _buildCoverPlaceholder(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: Colors.black.withValues(
                              alpha: _coverHovered ? .32 : .06,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _coverHovered || compact ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .94,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.camera,
                                            size: 16,
                                            color: AdminTheme.primaryDark,
                                          ),
                                          SizedBox(width: 7),
                                          Text(
                                            'Cambiar portada',
                                            style: TextStyle(
                                              color: AdminTheme.primaryDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
                Positioned(
                  left: 24,
                  top: 162,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AdminTheme.shadowMd,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: ColoredBox(
                              color: AdminTheme.primaryColor,
                              child: _selectedLogoBytes != null
                                  ? Image.memory(
                                      _selectedLogoBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : _restaurante!.logo != null
                                  ? Image.network(
                                      _mediaUrl(_restaurante!.logo!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _logoInitial(),
                                    )
                                  : _logoInitial(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        bottom: -4,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            onPressed: _pickLogo,
                            tooltip: 'Cambiar logo',
                            icon: const Icon(
                              LucideIcons.camera,
                              size: 15,
                              color: AdminTheme.primaryColor,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  Positioned(
                    top: 222,
                    left: 144,
                    right: 0,
                    child: _coverHint(),
                  ),
              ],
            ),
          ),
          if (compact) ...[const SizedBox(height: 4), _coverHint()],
        ],
      );
    },
  );

  Widget _buildCoverPlaceholder() => Container(
    color: AdminTheme.surfaceMuted,
    alignment: Alignment.center,
    child: const Icon(LucideIcons.image, size: 42, color: AdminTheme.textLight),
  );

  Widget _logoInitial() => Center(
    child: Text(
      _nombreCtrl.text.trim().isEmpty
          ? '?'
          : _nombreCtrl.text.trim().substring(0, 1).toUpperCase(),
      style: AdminTheme.titleStyle.copyWith(fontSize: 42, color: Colors.white),
    ),
  );

  Widget _coverHint() => Row(
    children: [
      const Icon(LucideIcons.info, size: 16, color: AdminTheme.gold),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          'La portada se muestra en tu perfil público y en la app de comensales.',
          style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
        ),
      ),
    ],
  );

  Widget _buildInfo(bool narrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (narrow) ...[
        _buildTextField(
          'Nombre del restaurante',
          _nombreCtrl,
          icon: LucideIcons.store,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          'Teléfono / WhatsApp',
          _telefonoCtrl,
          icon: LucideIcons.phone,
        ),
      ] else
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Nombre del restaurante',
                _nombreCtrl,
                icon: LucideIcons.store,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Teléfono / WhatsApp',
                _telefonoCtrl,
                icon: LucideIcons.phone,
              ),
            ),
          ],
        ),
      const SizedBox(height: 18),
      _buildTextField(
        'Correo de contacto',
        _correoCtrl,
        icon: LucideIcons.mail,
      ),
      const SizedBox(height: 22),
      _buildTiposComidaSelector(),
      const SizedBox(height: 22),
      _buildTextField(
        'Descripción',
        _descripcionCtrl,
        maxLines: 4,
        maxLength: 300,
      ),
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
    ],
  );

  Widget _buildLocation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: _abrirMapaModal,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 230,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                            'Mapa no disponible en esta plataforma',
                          ),
                        ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      constraints: const BoxConstraints(maxWidth: 410),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: AdminTheme.shadowSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: AdminTheme.primaryColor,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              _nombreCtrl.text.isEmpty
                                  ? 'Seleccionar ubicación'
                                  : _nombreCtrl.text,
                              overflow: TextOverflow.ellipsis,
                              style: AdminTheme.bodyStyle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 13,
                  top: 13,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      _buildTextField('Dirección', _direccionCtrl, icon: LucideIcons.mapPin),
    ],
  );

  Widget _buildHorariosBlock() {
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
        for (var day = 0; day < 7; day++) ...[
          if (day > 0) const Divider(height: 22, color: AdminTheme.rowBorder),
          _buildHorarioDia(day, dias[day]),
        ],
      ],
    );
  }

  Widget _buildHorarioDia(int day, String name) {
    final entries = _horarios.where((h) => h['diaSemana'] == day).toList();
    final active = entries.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 510;
        final timeControls = active
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: _timeInput(entries[i], 'horaInicio')),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          child: Text('—'),
                        ),
                        Flexible(child: _timeInput(entries[i], 'horaFin')),
                        if (entries.length > 1)
                          IconButton(
                            tooltip: 'Quitar intervalo',
                            onPressed: () => setState(() {
                              _horarios.remove(entries[i]);
                              _isDirty = true;
                            }),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AdminTheme.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (entries.length > 1) const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _horarios.add({
                        'diaSemana': day,
                        'horaInicio': '08:00',
                        'horaFin': '22:00',
                      });
                      _isDirty = true;
                    }),
                    icon: const Icon(LucideIcons.plus, size: 13),
                    label: const Text('Otro intervalo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 13,
                      color: AdminTheme.textMuted,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Cerrado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: compact ? 86 : 120,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AdminTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AdminTheme.textDark
                            : AdminTheme.textMuted,
                      ),
                    ),
                    if (active)
                      Text(
                        entries
                            .map((h) => '${h['horaInicio']}–${h['horaFin']}')
                            .join(', '),
                        style: AdminTheme.bodyStyle.copyWith(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() {
                if (active) {
                  _horarios.removeWhere((h) => h['diaSemana'] == day);
                } else {
                  _horarios.add({
                    'diaSemana': day,
                    'horaInicio': '08:00',
                    'horaFin': '22:00',
                  });
                }
                _isDirty = true;
              }),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active
                      ? AdminTheme.primaryColor
                      : const Color(0xFFE3DACA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment: active
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x3026201A), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(active), child: timeControls),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _timeInput(Map<String, dynamic> horario, String key) => SizedBox(
    width: 110,
    child: TextFormField(
      key: ValueKey((horario, key)),
      initialValue: horario[key]?.toString() ?? '',
      style: AdminTheme.bodyStyle.copyWith(
        color: AdminTheme.textDark,
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
      decoration: _fieldDecoration(null).copyWith(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      ),
      onChanged: (value) {
        horario[key] = value;
        _markDirty();
      },
    ),
  );

  Widget _buildMesasBlock(bool narrow) {
    final tables = _buildStepper(
      'TOTAL DE MESAS',
      LucideIcons.store,
      AdminTheme.primaryColor,
      AdminTheme.primaryLight,
      _mesasTotalCtrl,
      1,
    );
    final capacity = _buildStepper(
      'CAPACIDAD TOTAL',
      LucideIcons.users,
      AdminTheme.accentColor,
      AdminTheme.accentSoft,
      _capacidadTotalCtrl,
      int.tryParse(_mesasTotalCtrl.text) ?? 1,
    );
    return narrow
        ? Column(children: [tables, const SizedBox(height: 12), capacity])
        : Row(
            children: [
              Expanded(child: tables),
              const SizedBox(width: 14),
              Expanded(child: capacity),
            ],
          );
  }

  Widget _buildStepper(
    String label,
    IconData icon,
    Color iconColor,
    Color iconBg,
    TextEditingController controller,
    int min,
  ) {
    final value = int.tryParse(controller.text) ?? min;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: AdminTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AdminTheme.titleStyle.copyWith(fontSize: 32),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
              ),
              Column(
                children: [
                  _stepperButton(
                    LucideIcons.plus,
                    () => setState(() => controller.text = '${value + 1}'),
                  ),
                  const SizedBox(height: 6),
                  _stepperButton(
                    LucideIcons.minus,
                    value <= min
                        ? null
                        : () =>
                              setState(() => controller.text = '${value - 1}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onPressed) => SizedBox(
    width: 34,
    height: 34,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
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
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.background,
          border: Border.all(
            color: const Color(0xFFD5C9B8),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 17, color: AdminTheme.gold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Mínimo 5 fotos de alta calidad para publicar tu restaurante ante los comensales.',
                style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 620 ? 3 : 4;
          final total = _existingGallery.length + _selectedGalleryBytes.length;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: total + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index == total) {
                return _buildAddPhotoTile();
              }
              if (index < _existingGallery.length) {
                final image = _existingGallery[index];
                return _buildGaleriaItem(
                  networkUrl: image['url']?.toString(),
                  imageId: (image['id'] as num?)?.toInt(),
                );
              }
              final selectedIndex = index - _existingGallery.length;
              return _buildGaleriaItem(
                bytes: _selectedGalleryBytes[selectedIndex],
                index: selectedIndex,
              );
            },
          );
        },
      ),
    ],
  );

  Widget _buildAddPhotoTile() => InkWell(
    onTap: _pickGallery,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5C9B8), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.plus,
            size: 24,
            color: AdminTheme.primaryColor,
          ),
          const SizedBox(height: 8),
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

  Widget _buildGaleriaItem({
    String? networkUrl,
    Uint8List? bytes,
    int? index,
    int? imageId,
  }) {
    var hovered = false;
    return StatefulBuilder(
      builder: (context, localSetState) => MouseRegion(
        onEnter: (_) => localSetState(() => hovered = true),
        onExit: (_) => localSetState(() => hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: hovered ? 1.07 : 1,
                duration: const Duration(milliseconds: 400),
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : networkUrl != null
                    ? Image.network(
                        _mediaUrl(networkUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildCoverPlaceholder(),
                      )
                    : _buildCoverPlaceholder(),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: hovered ? const Color(0x801C1611) : Colors.transparent,
              ),
              IgnorePointer(
                ignoring: !hovered && MediaQuery.sizeOf(context).width > 720,
                child: AnimatedOpacity(
                  opacity: hovered || MediaQuery.sizeOf(context).width <= 720
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Quitar fotografía',
                          onPressed: () => setState(() {
                            if (index != null) {
                              _selectedGallery.removeAt(index);
                              _selectedGalleryBytes.removeAt(index);
                            } else if (imageId != null) {
                              _existingGallery.removeWhere(
                                (image) =>
                                    (image['id'] as num?)?.toInt() == imageId,
                              );
                              if (!_deletedGalleryIds.contains(imageId)) {
                                _deletedGalleryIds.add(imageId);
                              }
                            }
                            _isDirty = true;
                          }),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 17,
                            color: AdminTheme.error,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textDark,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark),
          decoration: _fieldDecoration(icon).copyWith(counterText: ''),
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(IconData? icon) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 17, color: AdminTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.error, width: 1.5),
    ),
  );

  String _mediaUrl(String url) =>
      url.startsWith('http') ? url : '${ApiEndpoints.baseUrl}$url';
}
