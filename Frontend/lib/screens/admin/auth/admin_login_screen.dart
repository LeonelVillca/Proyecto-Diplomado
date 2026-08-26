import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': _correoCtrl.text.trim(), 'password': _passwordCtrl.text}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        if (token != null) {
          final auth = AuthScope.of(context);
          final success = await auth.restaurarSesionLocalDesdeAdmin(token);
          if (success && mounted) {
            if (auth.hasRole('admin_sistema')) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminSistemaDashboard()));
            } else if (auth.hasRole('admin_restaurante')) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminRestauranteDashboard()));
            } else {
              auth.signOut();
              _mostrarErrorPermisos();
            }
          }
        }
      } else {
        _mostrarError('Credenciales inválidas o cuenta suspendida.');
      }
    } catch (_) {
      _mostrarError('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Karla')), backgroundColor: const Color(0xFF6B1A35)),
    );
  }

  void _mostrarErrorPermisos() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Acceso Denegado', style: TextStyle(fontFamily: 'BodoniModa', color: Colors.white, fontSize: 22)),
        content: const Text(
          'Tu cuenta no tiene permisos para acceder al Panel Administrativo.\n\nContacta a soporte si crees que es un error.',
          style: TextStyle(fontFamily: 'Karla', color: Color(0xAAFFFFFF), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Karla', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0401),
      body: Row(
        children: [
          // ── LADO IZQUIERDO: imagen con overlay ──────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/restaurant_hero.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset('assets/fondo_tarija.jpg', fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xBB0D0401), Color(0x440D0401)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
                // Texto sobre la imagen
                Positioned(
                  bottom: 60, left: 50, right: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✦  PANEL ADMINISTRATIVO',
                          style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Karla', fontSize: 12, letterSpacing: 2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Gestiona tu\nRestaurante\ndesde cualquier\nlugar',
                        style: TextStyle(
                          fontFamily: 'BodoniModa',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _FeatureChip(Icons.calendar_month_outlined, 'Reservas en tiempo real'),
                          const SizedBox(width: 12),
                          _FeatureChip(Icons.star_outline, 'Gestión de reseñas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── LADO DERECHO: formulario ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0D0401),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideIn,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Mesa Chapaca',
                                  style: TextStyle(
                                    fontFamily: 'BodoniModa',
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Bienvenido de vuelta',
                              style: TextStyle(
                                fontFamily: 'BodoniModa',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ingresa tus credenciales para continuar al panel.',
                              style: TextStyle(fontFamily: 'Karla', fontSize: 15, color: Color(0x88FFFFFF), height: 1.4),
                            ),
                            const SizedBox(height: 28),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email field
                                  _LoginField(
                                    controller: _correoCtrl,
                                    label: 'Correo electrónico',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  // Password field
                                  _LoginField(
                                    controller: _passwordCtrl,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureText,
                                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                    onFieldSubmitted: (_) => _login(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0x55FFFFFF),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureText = !_obscureText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: const Color(0xFF1A0A00),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A0A00)),
                                      )
                                    : const Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Karla', letterSpacing: 0.5),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Back
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                '← Volver al inicio',
                                style: TextStyle(color: Color(0x66FFFFFF), fontFamily: 'Karla', fontSize: 14),
                              ),
                            ),

                            const SizedBox(height: 28),
                            // divider + help
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: const Color(0x22FFFFFF))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('¿Necesitas acceso?', style: TextStyle(color: Color(0x55FFFFFF), fontFamily: 'Karla', fontSize: 13)),
                                ),
                                Expanded(child: Container(height: 1, color: const Color(0x22FFFFFF))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x33FFFFFF)),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Solicitar acceso para mi restaurante', style: TextStyle(fontFamily: 'Karla', fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontFamily: 'Karla', fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x66FFFFFF), fontFamily: 'Karla'),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A0A00),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6B1A35)),
        ),
        errorStyle: const TextStyle(fontFamily: 'Karla'),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Karla', fontSize: 13)),
        ],
      ),
    );
  }
}
