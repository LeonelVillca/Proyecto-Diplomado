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

part 'perfil_restaurante/controlador_perfil.dart';
part 'perfil_restaurante/servicio_perfil.dart';
part '../../../widgets/admin/perfil_restaurante/encabezado_perfil.dart';
part '../../../widgets/admin/perfil_restaurante/selector_tipos_comida.dart';
part '../../../widgets/admin/perfil_restaurante/paso_identidad_restaurante.dart';
part '../../../widgets/admin/perfil_restaurante/paso_informacion_restaurante.dart';
part '../../../widgets/admin/perfil_restaurante/paso_ubicacion_restaurante.dart';
part '../../../widgets/admin/perfil_restaurante/paso_horarios_restaurante.dart';
part '../../../widgets/admin/perfil_restaurante/paso_mesas_restaurante.dart';
part '../../../widgets/admin/perfil_restaurante/selector_galeria.dart';
part '../../../widgets/admin/perfil_restaurante/campo_formulario.dart';

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
                          PasoIdentidadRestaurante(pantalla: this),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Información principal',
                          'Los datos que describen tu restaurante.',
                          LucideIcons.store,
                          AdminTheme.accentSoft,
                          AdminTheme.accentColor,
                          PasoInformacionRestaurante(
                            pantalla: this,
                            estrecho: narrow,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Ubicación exacta',
                          'Ayuda a tus comensales a encontrarte.',
                          LucideIcons.mapPin,
                          const Color(0xFFEFE9F6),
                          const Color(0xFF78628E),
                          PasoUbicacionRestaurante(pantalla: this),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Horarios de atención',
                          'Define cuándo pueden visitarte.',
                          LucideIcons.clock,
                          AdminTheme.warningSoft,
                          AdminTheme.gold,
                          PasoHorariosRestaurante(pantalla: this),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Configuración de salón',
                          'Capacidad disponible para tus reservas.',
                          Icons.chair_outlined,
                          AdminTheme.primaryLight,
                          AdminTheme.primaryColor,
                          PasoMesasRestaurante(
                            pantalla: this,
                            estrecho: narrow,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Galería de fotos',
                          'Muestra tu ambiente y tus mejores platos.',
                          Icons.photo_library_outlined,
                          AdminTheme.warningSoft,
                          AdminTheme.gold,
                          SelectorGaleriaRestaurante(pantalla: this),
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
}
