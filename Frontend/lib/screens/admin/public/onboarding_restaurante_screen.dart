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

part 'onboarding_restaurante/controlador_onboarding.dart';
part 'onboarding_restaurante/servicio_onboarding.dart';
part '../../../widgets/admin/onboarding/indicador_pasos.dart';
part '../../../widgets/admin/onboarding/navegacion_pasos.dart';
part '../../../widgets/admin/onboarding/paso_identidad_restaurante.dart';
part '../../../widgets/admin/onboarding/paso_ubicacion_horarios.dart';
part '../../../widgets/admin/onboarding/paso_capacidad_salon.dart';
part '../../../widgets/admin/onboarding/selector_galeria.dart';
part '../../../widgets/admin/onboarding/tarjeta_seccion.dart';
part '../../../widgets/admin/onboarding/campo_formulario.dart';

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
              IndicadorPasos(pantalla: this, compacto: true),
              Expanded(child: _mainPane(mobile: mobile, tablet: true)),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(
              width: 330,
              child: IndicadorPasos(pantalla: this, compacto: false),
            ),
            Expanded(child: _mainPane(mobile: false, tablet: false)),
          ],
        );
      },
    ),
  );
}
