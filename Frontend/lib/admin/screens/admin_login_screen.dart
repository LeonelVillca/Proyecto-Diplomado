import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import 'admin_sistema_dashboard.dart';
import 'admin_restaurante_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/login');
      final body = {
        'correo': _correoCtrl.text.trim(),
        'password': _passwordCtrl.text,
      };

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        if (token != null) {
          final authProvider = AuthScope.of(context);
          final success = await authProvider.restaurarSesionLocalDesdeAdmin(token);
          
          if (success && mounted) {
            if (authProvider.hasRole('admin_sistema')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminSistemaDashboard()),
              );
            } else if (authProvider.hasRole('admin_restaurante')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminRestauranteDashboard()),
              );
            } else {
              // No tiene permisos de administrador
              authProvider.signOut();
              _mostrarErrorPermisos();
            }
          }
        }
      } else {
        _mostrarError('Credenciales inválidas o cuenta suspendida.');
      }
    } catch (e) {
      _mostrarError('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  void _mostrarErrorPermisos() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acceso Denegado', style: TextStyle(fontFamily: 'BodoniModa', color: Colors.red)),
        content: const Text(
          'Tu cuenta no tiene los permisos necesarios para acceder al Panel Administrativo.\n\nSi crees que esto es un error, por favor contacta a soporte.',
          style: TextStyle(fontFamily: 'Karla', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE), // Crema
      body: Row(
        children: [
          // Lado Izquierdo: Formulario
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_menu, color: Color(0xFF6B1A35), size: 40),
                            const SizedBox(width: 12),
                            Text(
                              'Mesa Chapaca',
                              style: const TextStyle(
                                color: Color(0xFF6B1A35),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'BodoniModa',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Panel Administrativo',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                            fontFamily: 'Karla',
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        const Text(
                          'Bienvenido de vuelta',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BodoniModa',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus credenciales para continuar',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontFamily: 'Karla',
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            labelStyle: const TextStyle(fontFamily: 'Karla'),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B1A35)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6B1A35), width: 2),
                            ),
                          ),
                          validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: const TextStyle(fontFamily: 'Karla'),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B1A35)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6B1A35), width: 2),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B1A35),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Karla',
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Volver a la landing
                          },
                          child: Text(
                            'Volver al inicio',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontFamily: 'Karla',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Lado Derecho: Imagen Hero
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fondo_tarija.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B1A35).withOpacity(0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
