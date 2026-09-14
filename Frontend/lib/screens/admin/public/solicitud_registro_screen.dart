import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/widgets/admin/landing_navbar.dart';
import 'package:frontend/widgets/admin/solicitud_hero.dart';
import 'package:frontend/widgets/admin/landing_footer.dart';
import 'package:frontend/screens/admin/public/landing_screen.dart';
import 'package:frontend/screens/admin/auth/widgets/auth_components.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

class SolicitudRegistroScreen extends StatefulWidget {
  const SolicitudRegistroScreen({super.key});

  @override
  State<SolicitudRegistroScreen> createState() => _SolicitudRegistroScreenState();
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
    
    setState(() {
      _isLoading = true;
    });

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
        final nitBytes = _nitFile!.bytes;
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentoNit',
            nitBytes!,
            filename: _nitFile!.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      }
      if (_ciFile != null) {
        final ciBytes = _ciFile!.bytes;
        request.files.add(
          http.MultipartFile.fromBytes(
            'documentoCi',
            ciBytes!,
            filename: _ciFile!.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 201) {
        setState(() {
          _isSuccess = true;
        });
      } else {
        _mostrarError('Error al enviar la solicitud. Intenta nuevamente.');
      }
    } catch (e) {
      _mostrarError('Error de red. Verifica tu conexión.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarArchivo(bool esNit) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (esNit) {
          _nitFile = result.files.first;
        } else {
          _ciFile = result.files.first;
        }
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
      backgroundColor: const Color(0xFFF5EEE0), // paper
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: LandingNavbar(showLinks: false)),
          const SliverToBoxAdapter(child: SolicitudHero()),
          SliverToBoxAdapter(
            child: Center(
              child: _isSuccess ? _buildSuccess() : _buildForm(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LandingFooter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          Text(
            'Solicitud enviada con éxito',
            style: GoogleFonts.piazzolla(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B1233), // wine
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hemos recibido tus datos. Nuestro equipo se pondrá en contacto contigo pronto.',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF7A6A5C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminLandingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B1233),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('Volver al inicio', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Comience hoy mismo.',
                style: GoogleFonts.piazzolla(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF241512), // ink
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Un miembro de nuestro equipo se pondrá en contacto con usted en breve para hablar sobre sus necesidades.',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: const Color(0xFF7A6A5C), // ink-soft
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(height: 4, color: const Color(0xFF6B1233)), // wine
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(height: 4, color: _currentStep == 2 ? const Color(0xFF6B1233) : const Color(0xFFEAE0C9)), // wine : paper-deep
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text(
                '¡Empecemos!',
                style: GoogleFonts.piazzolla(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF241512), // ink
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentStep == 1 
                    ? 'Cuéntanos un poco sobre ti para que podamos personalizar tu experiencia.'
                    : 'Necesitamos algunos documentos para validar tu restaurante.',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: const Color(0xFF7A6A5C), // ink-soft
                ),
              ),
              const SizedBox(height: 32),
              
              if (_currentStep == 1) ...[
                AuthLoginField(
                  label: 'NOMBRE DE PILA *',
                  hintText: 'Tu nombre',
                  icon: Icons.person_outline,
                  controller: _nombreCtrl,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                AuthLoginField(
                  label: 'APELLIDO *',
                  hintText: 'Tu apellido',
                  icon: Icons.person_outline,
                  controller: _apellidoCtrl,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                AuthLoginField(
                  label: 'CORREO ELECTRÓNICO *',
                  hintText: 'tunombre@correo.com',
                  icon: Icons.email_outlined,
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AuthLoginField(
                        label: 'RESTAURANTE *',
                        hintText: 'Nombre de tu negocio',
                        icon: Icons.storefront_outlined,
                        controller: _restauranteCtrl,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: AuthLoginField(
                        label: 'TELÉFONO *',
                        hintText: 'Número de celular',
                        icon: Icons.phone_outlined,
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AuthLoginField(
                  label: 'MENSAJE O DESCRIPCIÓN (Opcional)',
                  hintText: 'Cuéntanos un poco sobre tu restaurante...',
                  icon: Icons.description_outlined,
                  controller: _descripcionCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 200,
                    child: AuthSubmitButton(
                      label: 'Siguiente',
                      loading: false,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _currentStep = 2);
                        }
                      },
                    ),
                  ),
                ),
              ] else ...[
                AuthLoginField(
                  label: 'NIT DEL NEGOCIO *',
                  hintText: 'Ingresa tu NIT',
                  icon: Icons.badge_outlined,
                  controller: _nitCtrl,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 32),
                
                Text(
                  'DOCUMENTO NIT (Solo PDF) *',
                  style: GoogleFonts.manrope(color: const Color(0xFF8C7A6B), fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _seleccionarArchivo(true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _nitFile != null ? const Color(0xFF6B1233) : const Color(0xFFDCD6CC), width: _nitFile != null ? 1.6 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_outlined, color: _nitFile != null ? const Color(0xFF6B1233) : const Color(0xFF8C7A6B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _nitFile != null ? _nitFile!.name : 'Haz clic aquí para seleccionar el archivo',
                            style: GoogleFonts.manrope(
                              color: _nitFile != null ? const Color(0xFF241512) : const Color(0xFF8C7A6B),
                              fontWeight: _nitFile != null ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_nitFile != null) const Icon(Icons.check_circle, color: Color(0xFF5C7A52)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'CÉDULA DE IDENTIDAD (Solo PDF) *',
                  style: GoogleFonts.manrope(color: const Color(0xFF8C7A6B), fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _seleccionarArchivo(false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ciFile != null ? const Color(0xFF6B1233) : const Color(0xFFDCD6CC), width: _ciFile != null ? 1.6 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_outlined, color: _ciFile != null ? const Color(0xFF6B1233) : const Color(0xFF8C7A6B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _ciFile != null ? _ciFile!.name : 'Haz clic aquí para seleccionar el archivo',
                            style: GoogleFonts.manrope(
                              color: _ciFile != null ? const Color(0xFF241512) : const Color(0xFF8C7A6B),
                              fontWeight: _ciFile != null ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_ciFile != null) const Icon(Icons.check_circle, color: Color(0xFF5C7A52)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFF7A6A5C)),
                      label: Text('Atrás', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF7A6A5C))),
                    ),
                    SizedBox(
                      width: 220,
                      child: AuthSubmitButton(
                        label: 'Enviar Solicitud',
                        loading: _isLoading,
                        onPressed: _enviarSolicitud,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 40),
              Text(
                'Al hacer clic en «Próximo», acepta nuestra Política de privacidad.\n\nTambién acepta recibir comunicaciones de marketing de Mesa Chapaca sobre noticias, eventos, promociones y boletines mensuales. Puede cancelar su suscripción a los correos electrónicos en cualquier momento.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF7A6A5C), // ink-soft
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
