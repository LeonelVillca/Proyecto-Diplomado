import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

class CrearContrasenaScreen extends StatefulWidget {
  final String? token;

  const CrearContrasenaScreen({super.key, this.token});

  @override
  State<CrearContrasenaScreen> createState() => _CrearContrasenaScreenState();
}

class _CrearContrasenaScreenState extends State<CrearContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _crearContrasena() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.token == null || widget.token!.isEmpty) {
      _mostrarMensaje('No se encontró un token válido. Por favor, solicita un nuevo enlace.', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/crear-contrasena'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': widget.token,
          'password': _passwordCtrl.text,
        }),
      );

      if (res.statusCode == 200) {
        setState(() => _isSuccess = true);
      } else {
        final body = jsonDecode(res.body);
        _mostrarMensaje(body['message'] ?? 'Error al crear la contraseña.', true);
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión con el servidor.', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String msg, bool isError) {
    if (!mounted) return;
    if (isError) {
      AdminNotificationModal.error(context, msg);
    } else {
      AdminNotificationModal.success(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEE0), // paper color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B1A35).withOpacity(0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: _isSuccess ? _buildSuccess(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF3E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 48, color: Color(0xFF6B1233)),
          ),
          const SizedBox(height: 24),
          Text(
            'Crea tu contraseña',
            textAlign: TextAlign.center,
            style: GoogleFonts.piazzolla(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF241512),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Establece tu nueva contraseña segura para acceder al panel de administración de Mesa Chapaca.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A6A5C),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildTextField(
            controller: _passwordCtrl,
            label: 'Nueva contraseña',
            icon: Icons.lock_outline_rounded,
            validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _confirmCtrl,
            label: 'Confirmar contraseña',
            icon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirma la contraseña';
              if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isLoading ? null : _crearContrasena,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B1233), // wine
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Guardar Contraseña', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF241512), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(color: const Color(0xFF7A6A5C), fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: const Color(0xFF8C7A6B), size: 22),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCD6CC), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6B1233), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF1F8B4C)),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Contraseña creada!',
          textAlign: TextAlign.center,
          style: GoogleFonts.piazzolla(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF241512),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu cuenta ya está segura. Ahora puedes iniciar sesión para acceder al panel de administración.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7A6A5C),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF241512), // ink
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text('Ir al Login', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ],
    );
  }
}
