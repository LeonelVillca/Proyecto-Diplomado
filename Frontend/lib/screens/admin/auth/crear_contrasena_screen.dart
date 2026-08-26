import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isSuccess ? _buildSuccess(context) : _buildForm(context),
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
          const Icon(Icons.lock_reset, size: 48, color: Color(0xFF6B1A35)),
          const SizedBox(height: 16),
          const Text(
            'Crear Contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Establece tu contraseña para acceder al panel de administración.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontFamily: 'Karla', color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              labelStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla'),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6B1A35), width: 2),
              ),
            ),
            validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              labelStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla'),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6B1A35), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor confirma la contraseña';
              if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _crearContrasena,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B1A35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Karla')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          '¡Contraseña creada!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Text(
          'Tu cuenta ya está segura. Ahora puedes iniciar sesión en el panel de administración.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontFamily: 'Karla', color: Colors.grey.shade600, height: 1.5),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Ir al Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Karla')),
        ),
      ],
    );
  }
}
