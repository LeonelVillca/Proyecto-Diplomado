import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/widgets/admin/landing_navbar.dart';
import 'package:frontend/widgets/admin/landing_footer.dart';
import 'package:frontend/widgets/admin/landing_tokens.dart';
import 'package:frontend/screens/admin/public/landing_screen.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

class SolicitudRegistroScreen extends StatefulWidget {
  const SolicitudRegistroScreen({super.key});

  @override
  State<SolicitudRegistroScreen> createState() =>
      _SolicitudRegistroScreenState();
}

class _SolicitudRegistroScreenState extends State<SolicitudRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _restauranteCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();

  int _currentStep = 1;
  PlatformFile? _nitFile;
  PlatformFile? _ciFile;
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nitFile == null || _ciFile == null) {
      _mostrarError('Debes adjuntar ambos documentos (NIT y CI).');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/solicitud');
      var request = http.MultipartRequest('POST', url);
      request.fields['nombreUsuario'] = _nombreCtrl.text.trim();
      request.fields['apellidoUsuario'] = _apellidoCtrl.text.trim();
      request.fields['correoUsuario'] = _correoCtrl.text.trim();
      request.fields['nombreRestaurante'] = _restauranteCtrl.text.trim();
      request.fields['celularContacto'] = _telefonoCtrl.text.trim();
      request.fields['descripcion'] = _descripcionCtrl.text.trim();
      request.fields['nitNegocio'] = _nitCtrl.text.trim();
      if (_nitFile != null) {
        final ext = _nitFile!.extension?.toLowerCase();
        request.files.add(http.MultipartFile.fromBytes(
          'documentoNit', _nitFile!.bytes!,
          filename: _nitFile!.name,
          contentType: ext == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', ext == 'jpg' ? 'jpeg' : ext!),
        ));
      }
      if (_ciFile != null) {
        final ext = _ciFile!.extension?.toLowerCase();
        request.files.add(http.MultipartFile.fromBytes(
          'documentoCi', _ciFile!.bytes!,
          filename: _ciFile!.name,
          contentType: ext == 'pdf' ? MediaType('application', 'pdf') : MediaType('image', ext == 'jpg' ? 'jpeg' : ext!),
        ));
      }
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      if (res.statusCode == 201) {
        setState(() => _isSuccess = true);
      } else {
        _mostrarError('Error al enviar la solicitud. Intenta nuevamente.');
      }
    } catch (e) {
      _mostrarError('Error de red. Verifica tu conexion.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarArchivo(bool esNit) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;
      if (picked.size > 5 * 1024 * 1024 ||
          picked.bytes == null ||
          !['pdf', 'jpg', 'jpeg', 'png'].contains(picked.extension?.toLowerCase())) {
        _mostrarError('El documento debe ser PDF, JPG o PNG y no superar 5 MB.');
        return;
      }
      setState(() {
        if (esNit) { _nitFile = picked; }
        else { _ciFile = picked; }
      });
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    AdminNotificationModal.error(context, msg);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _restauranteCtrl.dispose();
    _telefonoCtrl.dispose();
    _descripcionCtrl.dispose();
    _nitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingPalette.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
              SliverToBoxAdapter(
                child: Center(child: _isSuccess ? _buildSuccess() : _buildFormSection()),
              ),
              const SliverToBoxAdapter(child: LandingFooter()),
            ],
          ),
          Positioned(
            top: 18,
            left: 20,
            right: 20,
            child: LandingNavbar(
              showLinks: false,
              pageTitle: 'Registro de restaurante',
              onLogin: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: LandingPalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LandingPalette.line),
            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 40, offset: Offset(0, 16))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: LandingPalette.leafSoft,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(Icons.check_rounded, color: LandingPalette.leaf, size: 42),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Solicitud recibida',
                    style: LandingType.heading(size: 30, color: LandingPalette.ink),
                    textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(
                  'Recibimos tu solicitud y el equipo la revisará. Si es aprobada, enviaremos a este correo una invitación para crear tu contraseña y activar el acceso. No necesitas confirmar el correo antes de la revisión.',
                  style: LandingType.bodyText(size: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLandingScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: LandingPalette.wine,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: LandingType.bodyText(size: 16, weight: FontWeight.w700, color: Colors.white),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final h = LandingLayout.horizontalPadding(width);
      return Padding(
        padding: EdgeInsets.fromLTRB(h, 20, h, 64),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LandingPalette.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: LandingPalette.line),
                boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: Padding(
                padding: EdgeInsets.all(width < 600 ? 28 : 52),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormHeader(),
                      const SizedBox(height: 32),
                      _buildStepIndicator(),
                      const SizedBox(height: 36),
                      if (_currentStep == 1) _buildStep1(width) else _buildStep2(),
                      const SizedBox(height: 36),
                      _buildLegalNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionMarker('Formulario de registro'),
        const SizedBox(height: 16),
        Text(
          _currentStep == 1 ? 'Cuentanos sobre ti!' : 'Documentacion del negocio.',
          style: LandingType.heading(size: 34, color: LandingPalette.ink),
        ),
        const SizedBox(height: 10),
        Text(
          _currentStep == 1
              ? 'Comparte tu informacion para que podamos personalizar tu experiencia en Mesa Chapaca.'
              : 'Necesitamos estos documentos para validar y activar tu restaurante en la plataforma.',
          style: LandingType.bodyText(size: 15),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _StepDot(number: 1, active: true, done: _currentStep == 2),
          _StepLine(active: _currentStep == 2),
          _StepDot(number: 2, active: _currentStep == 2, done: false),
        ]),
        const SizedBox(height: 10),
        Text(
          _currentStep == 1 ? 'Paso 1 de 2  Datos personales' : 'Paso 2 de 2  Documentos legales',
          style: LandingType.bodyText(size: 13, color: LandingPalette.muted, weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStep1(double width) {
    final compact = width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          _LandingField(label: 'Nombre', hint: 'Tu nombre de pila', icon: Icons.person_outline_rounded, controller: _nombreCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
          const SizedBox(height: 20),
          _LandingField(label: 'Apellido', hint: 'Tu apellido', icon: Icons.person_outline_rounded, controller: _apellidoCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _LandingField(label: 'Nombre', hint: 'Tu nombre de pila', icon: Icons.person_outline_rounded, controller: _nombreCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null)),
            const SizedBox(width: 20),
            Expanded(child: _LandingField(label: 'Apellido', hint: 'Tu apellido', icon: Icons.person_outline_rounded, controller: _apellidoCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null)),
          ]),
        const SizedBox(height: 20),
        _LandingField(label: 'Correo electronico', hint: 'tunombre@correo.com', icon: Icons.email_outlined, controller: _correoCtrl, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo invalido' : null),
        const SizedBox(height: 20),
        if (compact) ...[
          _LandingField(label: 'Restaurante', hint: 'Nombre de tu negocio', icon: Icons.storefront_outlined, controller: _restauranteCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
          const SizedBox(height: 20),
          _LandingField(label: 'Telefono', hint: 'Numero de celular', icon: Icons.phone_outlined, controller: _telefonoCtrl, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _LandingField(label: 'Restaurante', hint: 'Nombre de tu negocio', icon: Icons.storefront_outlined, controller: _restauranteCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null)),
            const SizedBox(width: 20),
            Expanded(child: _LandingField(label: 'Telefono', hint: 'Numero de celular', icon: Icons.phone_outlined, controller: _telefonoCtrl, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo requerido' : null)),
          ]),
        const SizedBox(height: 20),
        _LandingField(label: 'Descripcion (opcional)', hint: 'Cuentanos un poco sobre tu restaurante...', icon: Icons.notes_rounded, controller: _descripcionCtrl, maxLines: 3),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: _LandingButton(
            label: 'Siguiente paso',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {
              if (_formKey.currentState!.validate()) setState(() => _currentStep = 2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LandingField(label: 'NIT del negocio', hint: 'Ingresa tu numero de NIT', icon: Icons.badge_outlined, controller: _nitCtrl, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
        const SizedBox(height: 28),
        _FilePickerField(label: 'Documento NIT', sublabel: 'PDF, JPG o PNG', file: _nitFile, onTap: () => _seleccionarArchivo(true)),
        const SizedBox(height: 20),
        _FilePickerField(label: 'Cedula de identidad', sublabel: 'PDF, JPG o PNG', file: _ciFile, onTap: () => _seleccionarArchivo(false)),
        const SizedBox(height: 36),
        Row(children: [
          _LandingBackButton(onPressed: _isLoading ? null : () => setState(() => _currentStep = 1)),
          const SizedBox(width: 16),
          Expanded(child: _LandingButton(label: 'Enviar solicitud', loading: _isLoading, onPressed: _enviarSolicitud)),
        ]),
      ],
    );
  }

  Widget _buildLegalNote() {
    return Text(
      'Al enviar este formulario, aceptas nuestra Politica de privacidad y autorizas a Mesa Chapaca a contactarte sobre tu solicitud y noticias relevantes.',
      style: LandingType.bodyText(size: 12, color: const Color(0xFF9A8A80), height: 1.6),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.active, required this.done});
  final int number;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final bg = done || active ? LandingPalette.wine : LandingPalette.paperDeep;
    final fg = done || active ? Colors.white : LandingPalette.muted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32, height: 32,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text('$number', style: LandingType.bodyText(size: 14, color: fg, weight: FontWeight.w700)),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: active ? LandingPalette.wine : LandingPalette.paperDeep,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _LandingField extends StatelessWidget {
  const _LandingField({
    required this.label, required this.hint,
    required this.icon, required this.controller,
    this.validator, this.keyboardType, this.maxLines = 1,
  });
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: LandingType.bodyText(size: 13, color: LandingPalette.ink, weight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: LandingType.bodyText(size: 15, color: LandingPalette.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: LandingType.bodyText(size: 15, color: const Color(0xFFAA9A90)),
          prefixIcon: Icon(icon, size: 20, color: LandingPalette.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: LandingPalette.paper,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LandingPalette.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LandingPalette.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LandingPalette.wine, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LandingPalette.terracotta)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LandingPalette.terracotta, width: 1.5)),
          errorStyle: LandingType.bodyText(size: 12, color: LandingPalette.terracotta),
        ),
      ),
    ],
  );
}

class _FilePickerField extends StatelessWidget {
  const _FilePickerField({required this.label, required this.sublabel, required this.file, required this.onTap});
  final String label, sublabel;
  final PlatformFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LandingType.bodyText(size: 13, color: LandingPalette.ink, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0x066B1233) : LandingPalette.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasFile ? LandingPalette.wine : LandingPalette.line, width: hasFile ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(hasFile ? Icons.insert_drive_file_outlined : Icons.upload_file_outlined, size: 22, color: hasFile ? LandingPalette.wine : LandingPalette.muted),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  hasFile ? file!.name : 'Seleccionar archivo',
                  style: LandingType.bodyText(size: 14, color: hasFile ? LandingPalette.ink : LandingPalette.muted, weight: hasFile ? FontWeight.w600 : FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!hasFile)
                  Text(sublabel, style: LandingType.bodyText(size: 12, color: const Color(0xFFAA9A90))),
              ])),
              if (hasFile)
                DecoratedBox(
                  decoration: BoxDecoration(color: LandingPalette.leafSoft, borderRadius: BorderRadius.circular(20)),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.check_rounded, size: 16, color: LandingPalette.leaf)),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LandingButton extends StatelessWidget {
  const _LandingButton({required this.label, required this.onPressed, this.trailingIcon, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: LandingPalette.wine,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0x806B1233),
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: LandingType.bodyText(size: 15, weight: FontWeight.w700, color: Colors.white),
    ),
    child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label),
            if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 18)],
          ]),
  );
}

class _LandingBackButton extends StatelessWidget {
  const _LandingBackButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: LandingPalette.muted,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: LandingType.bodyText(size: 14, weight: FontWeight.w700, color: LandingPalette.muted),
    ),
    icon: const Icon(Icons.arrow_back_rounded, size: 18),
    label: const Text('Atras'),
  );
}
