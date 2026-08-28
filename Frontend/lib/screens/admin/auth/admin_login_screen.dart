import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';

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
  bool _rememberMe = false;
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
    AdminModal.show(
      context: context,
      title: 'Acceso Denegado',
      confirmText: 'Entendido',
      cancelText: null,
      confirmColor: const Color(0xFFD4AF37),
      onConfirm: () => Navigator.pop(context),
      content: const Text(
        'Tu cuenta no tiene permisos para acceder al Panel Administrativo.\n\nContacta a soporte si crees que es un error.',
        style: TextStyle(fontFamily: 'Karla', color: Color(0xFF1E1B1A), fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEE0), // paper
      body: Row(
        children: [
          // ── LADO IZQUIERDO: Ilustración en fondo blanco ─────────────────
          Expanded(
            flex: 11,
            child: Container(
              color: Colors.black, // Cambiado a negro por si la imagen tarda en cargar
              child: Stack(
                children: [
                  // Imagen principal ocupando TODO el espacio
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Image.asset(
                        'assets/eee.jpg',
                        fit: BoxFit.cover, // Para que llene todo y no queden franjas
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  // Logo sutil arriba con efecto cristal (glassmorphism)
                  Positioned(
                    top: 48,
                    left: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6B1233), Color(0xFF3A0A1B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF6B1233).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Mesa Chapaca',
                                style: GoogleFonts.piazzolla(
                                  fontSize: 22,
                                  color: Colors.white, // Blanco para que resalte sobre el collage oscuro
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LADO DERECHO: Formulario sobre fondo Paper ─────────────────────────────
          Expanded(
            flex: 9,
            child: Container(
              color: const Color(0xFFF5EEE0), // paper
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
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
                            // Back
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFF7A6A5C)),
                                label: Text(
                                  'Volver al inicio',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF7A6A5C), // ink-soft
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            Text(
                              'Bienvenido',
                              style: GoogleFonts.piazzolla(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF241512), // ink
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ingresa al panel administrativo de tu restaurante para\ngestionar reservas y más.',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7A6A5C), // ink-soft
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email field
                                  _LoginField(
                                    controller: _correoCtrl,
                                    label: 'CORREO ELECTRÓNICO',
                                    hintText: 'tunombre@correo.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                                  ),
                                  const SizedBox(height: 24),
                                  // Password field
                                  _LoginField(
                                    controller: _passwordCtrl,
                                    label: 'CONTRASEÑA',
                                    hintText: '••••••••',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureText,
                                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                    onFieldSubmitted: (_) => _login(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: const Color(0xFF7A6A5C), // ink-soft
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureText = !_obscureText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Recuérdame y Olvidaste contraseña
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                        activeColor: const Color(0xFF6B1233), // wine
                                        side: const BorderSide(color: Color(0xFFDCD6CC), width: 1.5), // border soft
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Mantener sesión',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF7A6A5C), // ink-soft
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {}, // placeholder
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerRight),
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: GoogleFonts.manrope(
                                      color: const Color(0xFF6B1233), // wine
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Login button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B1233), // wine
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(0xFF6B1233).withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24, width: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Ingresar',
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Box Registro link
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBE3D5), // Slightly darker paper for contrast
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '¿Tu restaurante aún no está en\nMesa Chapaca?',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF7A6A5C), // ink-soft
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen()),
                                      );
                                    },
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Solicitar registro gratis',
                                          style: GoogleFonts.manrope(
                                            color: const Color(0xFF6B1233), // wine
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF6B1233)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Footer de privacidad
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF8C7A6B)),
                                const SizedBox(width: 8),
                                Text(
                                  'Tus datos están protegidos y encriptados.',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF8C7A6B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: const Color(0xFF8C7A6B), // ink-soft a bit browner
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF241512).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.manrope(
              color: const Color(0xFF241512), // ink
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.manrope(
                color: const Color(0xFFB5A89D), // light placeholder
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFFC08A1E), size: 20), // gold accent
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.transparent, // Color is handled by outer Container
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEAE0C9), width: 1), // soft border
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEAE0C9), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6B1233), width: 1.5), // wine
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              errorStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ),
      ],
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
