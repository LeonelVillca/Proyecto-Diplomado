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

// ─── Paleta del sistema ─────────────────────────────────────────────────────
const Color _wine = Color(0xFF6B1233);
const Color _wineSoft = Color(0xFF8C3350);
const Color _wineDeep = Color(0xFF3A0A1B);
const Color _gold = Color(0xFFD4AF37);
const Color _goldAccent = Color(0xFFB0832B);
const Color _paper = Color(0xFFF5EEE0);
const Color _card = Color(0xFFFFFCF6);
const Color _ink = Color(0xFF241512);
const Color _inkSoft = Color(0xFF7A6A5C);
const Color _inkFaint = Color(0xFF8C7A6B);
const Color _sage = Color(0xFF5C7A52);

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _rememberMe = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _quoteFade;
  late Animation<Offset> _quoteSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _quoteFade = CurvedAnimation(
        parent: _animCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _quoteSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
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
        if (token != null && mounted) {
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
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Karla')),
        backgroundColor: _wine,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  void _mostrarErrorPermisos() {
    if (!mounted) return;
    AdminModal.show(
      context: context,
      title: 'Acceso Denegado',
      confirmText: 'Entendido',
      cancelText: null,
      confirmColor: _goldAccent,
      onConfirm: () => Navigator.pop(context),
      content: const Text(
        'Tu cuenta no tiene permisos para acceder al Panel Administrativo.\n\nContacta a soporte si crees que es un error.',
        style: TextStyle(fontFamily: 'Karla', color: _ink, fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Row(
        children: [
          // ── LADO IZQUIERDO: Visual editorial sobre la imagen ─────────────
          Expanded(
            flex: 5, // 40% para que el divisor vaya más a la izquierda
            child: _LeftVisual(
              fadeIn: _fadeIn,
              quoteFade: _quoteFade,
              quoteSlide: _quoteSlide,
            ),
          ),

          // ── LADO DERECHO: Formulario sobre fondo paper ───────────────────
          Expanded(
            flex: 5, // 60% para el formulario
            child: _RightPanel(
              fadeIn: _fadeIn,
              slideIn: _slideIn,
              formKey: _formKey,
              correoCtrl: _correoCtrl,
              passwordCtrl: _passwordCtrl,
              isLoading: _isLoading,
              obscureText: _obscureText,
              rememberMe: _rememberMe,
              onToggleObscure: () => setState(() => _obscureText = !_obscureText),
              onToggleRemember: (v) => setState(() => _rememberMe = v ?? false),
              onLogin: _login,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lado izquierdo: imagen + capa editorial ─────────────────────────────────

class _LeftVisual extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<double> quoteFade;
  final Animation<Offset> quoteSlide;

  const _LeftVisual({
    required this.fadeIn,
    required this.quoteFade,
    required this.quoteSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _wineDeep, // fondo mientras carga la imagen
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen principal a todo el panel, con tinte vino unificador.
          FadeTransition(
            opacity: fadeIn,
            child: Image.asset(
              'assets/eee.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            
             
            ),
          ),
          // Gradiente vertical: arriba deja respirar, abajo garantiza lectura.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00151516), Color(0x803A0A1B), Color(0xF22E0713)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Gradiente horizontal desde la izquierda para apoyar el texto.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x992E0713), Color(0x00000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // Logo con efecto cristal.
          Positioned(
            top: 40,
            left: 40,
            child: FadeTransition(
              opacity: fadeIn,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_wine, _wineDeep],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: _wineDeep.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mesa Chapaca',
                              style: GoogleFonts.piazzolla(
                                fontSize: 19,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Reservas en Tarija',
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
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

          // Eliminados los overlays inferiores a pedido del usuario (testimonio y tarjeta)
        ],
      ),
    );
  }
}

// ─── Lado derecho: formulario ────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<Offset> slideIn;
  final GlobalKey<FormState> formKey;
  final TextEditingController correoCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final bool obscureText;
  final bool rememberMe;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool?> onToggleRemember;
  final VoidCallback onLogin;

  const _RightPanel({
    required this.fadeIn,
    required this.slideIn,
    required this.formKey,
    required this.correoCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.obscureText,
    required this.rememberMe,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      child: Stack(
        children: [
          // Resplandor dorado decorativo arriba a la derecha.
          Positioned(
            top: -160,
            right: -140,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2ED4AF37), Color(0x00D4AF37)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24), // Reducido para evitar scrollbar
              child: FadeTransition(
                opacity: fadeIn,
                child: SlideTransition(
                  position: slideIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Volver al inicio.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: _inkSoft),
                            label: Text(
                              'Volver al inicio',
                              style: GoogleFonts.manrope(
                                color: _inkSoft,
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
                        const SizedBox(height: 24), 

                        // Título.
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.piazzolla(
                              fontSize: 38, // Ligeramente más pequeño para compacidad
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.08,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              const TextSpan(text: 'Bienvenido '),
                              TextSpan(
                                text: 'de vuelta',
                                style: GoogleFonts.piazzolla(
                                  color: _wine,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ingresa con tu correo y contraseña para gestionar tu restaurante.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _inkSoft,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24), // Reducido de 44

                        // Form.
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              _LoginField(
                                controller: correoCtrl,
                                label: 'CORREO ELECTRÓNICO',
                                hintText: 'tunombre@correo.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                              ),
                              const SizedBox(height: 24),
                              _LoginField(
                                controller: passwordCtrl,
                                label: 'CONTRASEÑA',
                                hintText: 'Escribe tu contraseña',
                                icon: Icons.lock_outline,
                                obscureText: obscureText,
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                onFieldSubmitted: (_) => onLogin(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _inkFaint,
                                    size: 20,
                                  ),
                                  onPressed: onToggleObscure,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mantener sesión · Olvidaste contraseña.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: rememberMe,
                                    onChanged: onToggleRemember,
                                    activeColor: _wine,
                                    side: const BorderSide(color: Color(0xFFDCD6CC), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Mantener sesión',
                                  style: GoogleFonts.manrope(
                                    color: _inkSoft,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {}, // placeholder (flujo de recuperación pendiente)
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerRight,
                              ),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: GoogleFonts.manrope(
                                  color: _wine,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20), // Reducido de 28

                        // Botón principal.
                        _SubmitButton(
                          label: 'Ingresar',
                          loading: isLoading,
                          onPressed: onLogin,
                        ),
                        const SizedBox(height: 20), // Reducido de 28

                        // CTA de registro.
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 10, 18),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAE0C9)),
                            boxShadow: [
                              BoxShadow(color: _ink.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _goldAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '¿Tu restaurante aún no está\nen Mesa Chapaca?',
                                  style: GoogleFonts.manrope(
                                    color: _inkSoft,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
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
                                      'Unirme',
                                      style: GoogleFonts.manrope(
                                        color: _wine,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.arrow_forward, size: 16, color: _wine),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20), // Reducido de 28

                        // Footer eliminado a pedido del usuario.
                      ],
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

// ─── Campo de login con foco y hover ─────────────────────────────────────────

class _LoginField extends StatefulWidget {
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
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  late final FocusNode _focusNode = FocusNode();
  bool _hovered = false;

  bool get _active => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.manrope(
            color: _inkFaint,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.text,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _active
                    ? _goldAccent
                    : _hovered
                        ? _wine.withValues(alpha: 0.35)
                        : Colors.transparent,
                width: _active ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _wineDeep.withValues(alpha: _active ? 0.09 : 0.045),
                  blurRadius: _active ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: GoogleFonts.manrope(
                color: _ink,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFFB5A89D),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  widget.icon,
                  color: _active ? _goldAccent : _inkFaint,
                  size: 20,
                ),
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                errorStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              validator: widget.validator,
              onFieldSubmitted: widget.onFieldSubmitted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botón principal con hover ───────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.loading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered && !widget.loading
                  ? [_wineSoft, _wine]
                  : [_wine, const Color(0xFF55102A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _wine.withValues(alpha: _hovered && !widget.loading ? 0.38 : 0.24),
                blurRadius: _hovered && !widget.loading ? 26 : 14,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}