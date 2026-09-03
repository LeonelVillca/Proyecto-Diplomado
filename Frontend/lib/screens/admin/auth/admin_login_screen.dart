import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';
import 'package:frontend/screens/admin/auth/widgets/auth_components.dart';


enum AuthScreenState {
  login,
  paso1Correo,
  paso2Pin,
  paso3NuevaContrasena,
  exito,
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  // Login State
  final _loginFormKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  // Recovery State
  final _recoveryFormKey = GlobalKey<FormState>();
  final _recoveryCorreoCtrl = TextEditingController();
  final List<TextEditingController> _pinCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  final _nuevaPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AuthScreenState _screenState = AuthScreenState.login;
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureRecoveryText = true;
  bool _rememberMe = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _quoteFade;
  late Animation<Offset> _quoteSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _quoteFade = CurvedAnimation(parent: _animCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _quoteSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    
    _nuevaPasswordCtrl.addListener(() => setState(() {}));
    _confirmPasswordCtrl.addListener(() => setState(() {}));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _recoveryCorreoCtrl.dispose();
    for (var c in _pinCtrls) { c.dispose(); }
    for (var f in _pinFocusNodes) { f.dispose(); }
    _nuevaPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Karla')),
        backgroundColor: isError ? authWine : authSage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  // --- API Calls ---
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
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
              if (!mounted) return;
              AdminModal.show(
                context: context,
                title: 'Acceso Denegado',
                confirmText: 'Entendido',
                cancelText: null,
                confirmColor: authGoldAccent,
                onConfirm: () => Navigator.pop(context),
                content: const Text(
                  'Tu cuenta no tiene permisos para acceder al Panel Administrativo.\n\nContacta a soporte si crees que es un error.',
                  style: TextStyle(fontFamily: 'Karla', color: authInk, fontSize: 15),
                ),
              );
            }
          }
        }
      } else {
        _mostrarMensaje('Credenciales inválidas o cuenta suspendida.');
      }
    } catch (_) {
      _mostrarMensaje('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _solicitarRecuperacion() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.authSolicitarRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': _recoveryCorreoCtrl.text.trim()}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _mostrarMensaje(data['mensaje'], isError: false);
        setState(() => _screenState = AuthScreenState.paso2Pin);
      } else {
        final error = jsonDecode(res.body);
        _mostrarMensaje(error['message'] ?? 'Error al solicitar recuperación.');
      }
    } catch (_) {
      _mostrarMensaje('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarPin() async {
    final pin = _pinCtrls.map((c) => c.text).join();
    if (pin.length < 6) {
      _mostrarMensaje('Ingresa el código completo de 6 dígitos.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.authVerificarPinRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _screenState = AuthScreenState.paso3NuevaContrasena);
      } else {
        final error = jsonDecode(res.body);
        _mostrarMensaje(error['message'] ?? 'El PIN es inválido o ha expirado.');
      }
    } catch (_) {
      _mostrarMensaje('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restablecerPassword() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    final pin = _pinCtrls.map((c) => c.text).join();
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiEndpoints.authRestablecerPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
          'nuevaContrasena': _nuevaPasswordCtrl.text,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _screenState = AuthScreenState.exito);
      } else {
        final error = jsonDecode(res.body);
        _mostrarMensaje(error['message'] ?? 'Error al actualizar contraseña.');
      }
    } catch (_) {
      _mostrarMensaje('Error de red. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    final leftVisual = AuthLeftVisual(
      fadeIn: _fadeIn,
      quoteFade: _quoteFade,
      quoteSlide: _quoteSlide,
    );

    final rightPanel = Container(
      color: authPaper,
      child: Stack(
        children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_screenState),
                        child: _buildCurrentState(),
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

    return Scaffold(
      backgroundColor: authPaper,
      body: isDesktop
          ? Row(
              children: [
                Expanded(flex: 5, child: leftVisual),
                Expanded(flex: 5, child: rightPanel),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 240, width: double.infinity, child: leftVisual),
                Expanded(child: rightPanel),
              ],
            ),
    );
  }

  Widget _buildCurrentState() {
    switch (_screenState) {
      case AuthScreenState.login:
        return _buildLoginState();
      case AuthScreenState.paso1Correo:
        return _buildPaso1();
      case AuthScreenState.paso2Pin:
        return _buildPaso2();
      case AuthScreenState.paso3NuevaContrasena:
        return _buildPaso3();
      case AuthScreenState.exito:
        return _buildExito();
    }
  }

  // ─── LOGIN STATE ─────────────────────────────────────────────────────────────
  Widget _buildLoginState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: authInkSoft),
            label: Text(
              'Volver al inicio',
              style: GoogleFonts.manrope(
                color: authInkSoft,
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
        RichText(
          text: TextSpan(
            style: GoogleFonts.piazzolla(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: authInk,
              height: 1.1,
              letterSpacing: -0.8,
            ),
            children: [
              const TextSpan(text: 'Bienvenido '),
              TextSpan(
                text: 'de vuelta',
                style: GoogleFonts.piazzolla(color: authWine, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ingresa con tu correo y contraseña para gestionar tu restaurante.',
          style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w500, color: authInkSoft, height: 1.4),
        ),
        const SizedBox(height: 24),
        Form(
          key: _loginFormKey,
          child: Column(
            children: [
              AuthLoginField(
                controller: _correoCtrl,
                label: 'CORREO ELECTRÓNICO',
                hintText: 'tunombre@correo.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 24),
              AuthLoginField(
                controller: _passwordCtrl,
                label: 'CONTRASEÑA',
                hintText: 'Escribe tu contraseña',
                icon: Icons.lock_outline,
                obscureText: _obscureText,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                onFieldSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: authInkFaint, size: 20),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: authWine,
                    side: const BorderSide(color: Color(0xFFDCD6CC), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Mantener sesión', style: GoogleFonts.manrope(color: authInkSoft, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            TextButton(
              onPressed: () {
                _recoveryCorreoCtrl.text = _correoCtrl.text;
                setState(() => _screenState = AuthScreenState.paso1Correo);
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerRight),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.manrope(color: authWine, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AuthSubmitButton(label: 'Ingresar', loading: _isLoading, onPressed: _login),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: authCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEAE0C9)),
            boxShadow: [BoxShadow(color: authInk.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(width: 3, height: 38, decoration: BoxDecoration(color: authGoldAccent, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '¿Tu restaurante aún no está\nen Mesa Chapaca?',
                  style: GoogleFonts.manrope(color: authInkSoft, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SolicitudRegistroScreen())),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unirme', style: GoogleFonts.manrope(color: authWine, fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward, size: 16, color: authWine),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: authInkSoft),
            const SizedBox(width: 6),
            Text(
              'Tus datos están protegidos y encriptados',
              style: GoogleFonts.manrope(color: authInkSoft, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  // ─── HELPER HEADER RECOVERY ────────────────────────────────────────────────
  Widget _buildRecoveryHeader(int step, {required VoidCallback onBack, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: authInkSoft),
            label: Text(
              step == 1 ? 'Volver al login' : 'Volver',
              style: GoogleFonts.manrope(color: authInkSoft, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isFilled ? authWine : const Color(0xFFE5DCD0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.piazzolla(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: authInk,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: authInkSoft, height: 1.4),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── PASO 1 ────────────────────────────────────────────────────────────────
  Widget _buildPaso1() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecoveryHeader(
            1,
            onBack: () => setState(() => _screenState = AuthScreenState.login),
            title: 'Recupera tu contraseña',
            subtitle: 'Ingresa el correo asociado a tu cuenta y te enviaremos un código de verificación.',
          ),
          AuthLoginField(
            controller: _recoveryCorreoCtrl,
            label: 'CORREO ELECTRÓNICO',
            hintText: 'tunombre@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 32),
          AuthSubmitButton(label: 'Enviar código', loading: _isLoading, onPressed: _solicitarRecuperacion),
        ],
      ),
    );
  }

  // ─── PASO 2 ────────────────────────────────────────────────────────────────
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRecoveryHeader(
          2,
          onBack: () => setState(() => _screenState = AuthScreenState.paso1Correo),
          title: 'Ingresa el código',
          subtitle: 'Enviamos un código de 6 dígitos a ${_recoveryCorreoCtrl.text}.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 5 ? 10 : 0),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_pinCtrls[index].text.isEmpty && index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                  child: TextFormField(
                    controller: _pinCtrls[index],
                    focusNode: _pinFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.manrope(color: authInk, fontWeight: FontWeight.w800, fontSize: 22),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFE5DCD0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFE5DCD0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: authWine, width: 2)),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _pinFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'El código vence en 15:00 minutos',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 13, color: authInkSoft, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        AuthSubmitButton(
          label: 'Verificar código',
          loading: _isLoading,
          disabled: _pinCtrls.map((c) => c.text).join().length < 6,
          onPressed: _verificarPin,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿No recibiste el código? ', style: GoogleFonts.manrope(fontSize: 14, color: authInkSoft, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: _isLoading ? null : _solicitarRecuperacion,
              child: Text(
                'Reenviar',
                style: GoogleFonts.manrope(fontSize: 14, color: authWine, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── PASO 3 ────────────────────────────────────────────────────────────────
  bool get _hasMinLength => _nuevaPasswordCtrl.text.length >= 8;
  bool get _hasRegex => RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[\d\W]).+$').hasMatch(_nuevaPasswordCtrl.text);
  bool get _hasMatch => _nuevaPasswordCtrl.text == _confirmPasswordCtrl.text && _nuevaPasswordCtrl.text.isNotEmpty;
  bool get _isPasswordValid => _hasMinLength && _hasRegex && _hasMatch;

  Widget _buildChecklistItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.check_circle_outline, color: isValid ? authSage : const Color(0xFFB5A89D), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(fontSize: 13.5, color: isValid ? authSage : authInkSoft, fontWeight: isValid ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecoveryHeader(
            3,
            onBack: () => setState(() => _screenState = AuthScreenState.paso2Pin),
            title: 'Crea una nueva contraseña',
            subtitle: 'Elige una contraseña segura que no hayas usado antes.',
          ),
          AuthLoginField(
            controller: _nuevaPasswordCtrl,
            label: 'NUEVA CONTRASEÑA',
            hintText: 'Escribe tu nueva contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
            suffixIcon: IconButton(
              icon: Icon(_obscureRecoveryText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: authInkFaint, size: 20),
              onPressed: () => setState(() => _obscureRecoveryText = !_obscureRecoveryText),
            ),
          ),
          const SizedBox(height: 24),
          AuthLoginField(
            controller: _confirmPasswordCtrl,
            label: 'CONFIRMAR CONTRASEÑA',
            hintText: 'Vuelve a escribir la contraseña',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
          ),
          const SizedBox(height: 24),
          _buildChecklistItem('Al menos 8 caracteres', _hasMinLength),
          _buildChecklistItem('Incluye mayúscula, minúscula y un número o símbolo', _hasRegex),
          _buildChecklistItem('Las contraseñas coinciden', _hasMatch),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: 'Guardar contraseña',
            loading: _isLoading,
            disabled: !_isPasswordValid,
            onPressed: _restablecerPassword,
          ),
        ],
      ),
    );
  }

  // ─── EXITO ─────────────────────────────────────────────────────────────────
  Widget _buildExito() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: authInk.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: authSage.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: authSage, size: 40),
          ),
          const SizedBox(height: 24),
          Text('¡Contraseña actualizada!', style: GoogleFonts.piazzolla(fontSize: 26, fontWeight: FontWeight.w700, color: authInk)),
          const SizedBox(height: 12),
          Text(
            'Ya puedes iniciar sesión con tu nueva contraseña.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w500, color: authInkSoft, height: 1.5),
          ),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: 'Volver a iniciar sesión',
            loading: false,
            onPressed: () {
              _correoCtrl.text = _recoveryCorreoCtrl.text;
              _passwordCtrl.clear();
              _nuevaPasswordCtrl.clear();
              _confirmPasswordCtrl.clear();
              for (var c in _pinCtrls) { c.clear(); }
              setState(() => _screenState = AuthScreenState.login);
            },
          ),
        ],
      ),
    );
  }
}

