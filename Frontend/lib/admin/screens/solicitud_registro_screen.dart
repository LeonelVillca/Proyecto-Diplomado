import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/solicitud_hero.dart';
import '../widgets/solicitud_footer.dart';
import '../widgets/solicitud_input.dart';
import 'landing_screen.dart';

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

  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/solicitud');
      final body = {
        'nombreUsuario': _nombreCtrl.text.trim(),
        'apellidoUsuario': _apellidoCtrl.text.trim(),
        'correoUsuario': _correoCtrl.text.trim(),
        'nombreRestaurante': _restauranteCtrl.text.trim(),
        'celularContacto': _telefonoCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
      };

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

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

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _restauranteCtrl.dispose();
    _telefonoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Fondo muy claro como OpenTable
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: LandingNavbar()),
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
              child: SolicitudFooter(),
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
          const Text(
            'Solicitud enviada con éxito',
            style: TextStyle(
              fontFamily: 'BodoniModa',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B1A35),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hemos recibido tus datos. Nuestro equipo se pondrá en contacto contigo pronto.',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              color: Colors.grey.shade600,
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
              backgroundColor: const Color(0xFF6B1A35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Volver al inicio', style: TextStyle(fontSize: 16)),
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
              const Text(
                'Comience hoy mismo.',
                style: TextStyle(
                  fontFamily: 'BodoniModa',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Un miembro de nuestro equipo se pondrá en contacto con usted en breve para hablar sobre sus necesidades.',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Simular la barra de progreso de OpenTable
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(height: 4, color: const Color(0xFFE53935)), // Rojo/Vino vibrante
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(height: 4, color: Colors.grey.shade200),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text(
                '¡Empecemos!',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuéntanos un poco sobre ti para que podamos personalizar tu experiencia.',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),
              
              SolicitudInput(
                label: 'Nombre de pila *',
                controller: _nombreCtrl,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              SolicitudInput(
                label: 'Apellido *',
                controller: _apellidoCtrl,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              SolicitudInput(
                label: 'Dirección de correo electrónico *',
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SolicitudInput(
                      label: 'Nombre del Restaurante *',
                      controller: _restauranteCtrl,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SolicitudInput(
                      label: 'Número de Teléfono *',
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SolicitudInput(
                label: 'Mensaje o Descripción (Opcional)',
                controller: _descripcionCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Como OpenTable
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // Bordes menos redondeados
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Próximo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              Text(
                'Al hacer clic en «Próximo», acepta nuestra Política de privacidad.\n\nTambién acepta recibir comunicaciones de marketing de Mesa Chapaca sobre noticias, eventos, promociones y boletines mensuales. Puede cancelar su suscripción a los correos electrónicos en cualquier momento.',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
