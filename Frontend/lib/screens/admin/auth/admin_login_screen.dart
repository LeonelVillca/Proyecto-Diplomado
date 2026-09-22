import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/admin/dashboard/admin_sistema_dashboard.dart';
import 'package:frontend/screens/admin/dashboard/admin_restaurante_dashboard.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/admin/public/solicitud_registro_screen.dart';
import 'package:frontend/screens/admin/auth/widgets/auth_components.dart';
import 'package:frontend/screens/admin/auth/auth_response_message.dart';
import 'package:frontend/screens/admin/auth/password_policy.dart';
import 'package:frontend/services/shared/secure_http.dart' as secure_http;

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

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _recoveryFormKey = GlobalKey<FormState>();
  final _recoveryCorreoCtrl = TextEditingController();
  final List<TextEditingController> _pinCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  final _nuevaPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  AuthScreenState _screenState = AuthScreenState.login;
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureRecoveryText = true;
  bool _rememberMe = false;
  String? _inlineMessage;
  bool _inlineMessageIsError = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _quoteFade;
  late Animation<Offset> _quoteSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _quoteFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _quoteSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _nuevaPasswordCtrl.addListener(() => setState(() {}));
    _confirmPasswordCtrl.addListener(() => setState(() {}));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _recoveryCorreoCtrl.dispose();
    for (var c in _pinCtrls) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    _nuevaPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String msg, {bool isError = true}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = msg;
      _inlineMessageIsError = isError;
    });
  }

  Widget _buildInlineMessage() {
    final isError = _inlineMessageIsError;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: _inlineMessage == null
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (isError ? const Color(0xFFD95C5C) : authSage)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isError ? const Color(0xFFD95C5C) : authSage)
                      .withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError ? const Color(0xFFD95C5C) : authSage,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _inlineMessage!,
                      style: GoogleFonts.manrope(
                        color: isError
                            ? const Color(0xFF9C3F3F)
                            : const Color(0xFF47703F),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _inlineMessage = null),
                    child: Icon(
                      Icons.close_rounded,
                      color: isError ? const Color(0xFFD95C5C) : authSage,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _correoCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        if (token != null && mounted) {
          final auth = AuthScope.of(context);
          final success = await auth.restaurarSesionLocalDesdeAdmin(token);
          if (success && mounted) {
            if (auth.hasRole('admin_sistema')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSistemaDashboard(),
                ),
              );
            } else if (auth.hasRole('admin_restaurante')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRestauranteDashboard(),
                ),
              );
            } else {
              auth.signOut();
              if (!mounted) return;
              _mostrarMensaje(
                'Tu cuenta no tiene permisos para acceder al Panel Administrativo. Contacta a soporte si crees que es un error.',
              );
            }
          }
        }
      } else {
        _mostrarMensaje('Credenciales invalidas o cuenta suspendida.');
      }
    } catch (_) {
      _mostrarMensaje('Error de red. Verifica tu conexion.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _solicitarRecuperacion() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authSolicitarRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': _recoveryCorreoCtrl.text.trim()}),
        timeout: const Duration(seconds: 60),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _mostrarMensaje(
          authResponseMessage(
            res.body,
            'Solicitud aceptada. Si el correo está registrado, recibirás un PIN.',
          ),
          isError: false,
        );
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.paso2Pin);
      } else {
        _mostrarMensaje(
          res.statusCode >= 500
              ? 'El servidor no pudo confirmar el envío. Si ya recibiste el correo, ingresa ese PIN; si no, espera un minuto antes de pedir otro.'
              : authHttpErrorMessage(
                  res.statusCode,
                  res.body,
                  'No se pudo solicitar el código. Revisa el correo e inténtalo nuevamente.',
                ),
        );
      }
    } on TimeoutException {
      _mostrarMensaje(
        'La solicitud tardó demasiado y no pudimos confirmar el resultado. Si ya recibiste el correo, ingresa el PIN; si no, espera un minuto antes de pedir otro.',
      );
    } on http.ClientException {
      _mostrarMensaje(
        'Se perdió la conexión antes de confirmar la solicitud. Si llegó el correo, usa ese PIN; si no, espera un minuto y vuelve a intentarlo.',
      );
    } catch (_) {
      _mostrarMensaje(
        'No pudimos confirmar la solicitud. Si llegó el correo, usa ese PIN; si no, espera un minuto antes de pedir otro.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarPin() async {
    final pin = _pinCtrls.map((c) => c.text).join();
    if (pin.length < 6) {
      _mostrarMensaje('Ingresa el codigo completo de 6 digitos.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authVerificarPinRecuperacion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
        }),
        timeout: const Duration(seconds: 30),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.paso3NuevaContrasena);
      } else {
        _mostrarMensaje(
          authHttpErrorMessage(
            res.statusCode,
            res.body,
            'El PIN es inválido o venció. Solicita un código nuevo e inténtalo otra vez.',
          ),
        );
      }
    } on TimeoutException {
      _mostrarMensaje(
        'La verificación tardó demasiado. Comprueba tu conexión e inténtalo otra vez.',
      );
    } on http.ClientException {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo otra vez.',
      );
    } catch (_) {
      _mostrarMensaje(
        'No se pudo verificar el PIN. Revisa tu conexión e inténtalo otra vez.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restablecerPassword() async {
    if (!_recoveryFormKey.currentState!.validate()) return;
    final passwordError = PasswordPolicy.validate(_nuevaPasswordCtrl.text);
    final confirmationError = PasswordPolicy.validateConfirmation(
      _nuevaPasswordCtrl.text,
      _confirmPasswordCtrl.text,
    );
    if (passwordError != null || confirmationError != null) {
      _mostrarMensaje(passwordError ?? confirmationError!);
      return;
    }
    final pin = _pinCtrls.map((c) => c.text).join();
    setState(() => _isLoading = true);
    try {
      final res = await secure_http.post(
        Uri.parse(ApiEndpoints.authRestablecerPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _recoveryCorreoCtrl.text.trim(),
          'pin': pin,
          'nuevaContrasena': _nuevaPasswordCtrl.text,
        }),
        timeout: const Duration(seconds: 45),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() => _screenState = AuthScreenState.exito);
      } else {
        _mostrarMensaje(
          res.statusCode >= 500
              ? 'El servidor no pudo confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.'
              : authHttpErrorMessage(
                  res.statusCode,
                  res.body,
                  'No se pudo actualizar la contraseña. Revisa el PIN y vuelve a intentarlo.',
                ),
        );
      }
    } on TimeoutException {
      _mostrarMensaje(
        'No pudimos confirmar si se guardó la contraseña. Prueba iniciar sesión con la nueva; si no funciona, vuelve a esta pantalla e inténtalo otra vez.',
      );
    } on http.ClientException {
      _mostrarMensaje(
        'Se perdió la conexión y no pudimos confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.',
      );
    } catch (_) {
      _mostrarMensaje(
        'No se pudo confirmar si se guardó. Prueba iniciar sesión con la nueva contraseña antes de reintentar.',
      );
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

    final rightPanel = Stack(
      children: [
        Positioned(
          top: 40,
          left: 40,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 16, color: authInkSoft),
            label: Text(
              'Volver al inicio',
              style: GoogleFonts.manrope(
                color: authInkSoft,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ),
        Positioned(
          top: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'PANEL DE RESTAURANTES',
              style: GoogleFonts.manrope(
                color: authInkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: 80,
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 44,
                      ),
                      decoration: BoxDecoration(
                        color: authCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder:
                            (
                              Widget? currentChild,
                              List<Widget> previousChildren,
                            ) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
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
          ),
        ),
      ],
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
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: leftVisual,
                ),
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

  Widget _buildLoginState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bienvenido de vuelta',
          style: GoogleFonts.piazzolla(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: authInk,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ingresa con tu cuenta para ver el salon de hoy.',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: authInkSoft,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _loginFormKey,
          child: Column(
            children: [
              AuthLoginField(
                controller: _correoCtrl,
                label: 'Correo electronico',
                hintText: 'correo@turestaurante.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Correo invalido' : null,
              ),
              const SizedBox(height: 24),
              AuthLoginField(
                controller: _passwordCtrl,
                label: 'Contrasena',
                hintText: 'Tu contrasena',
                icon: Icons.lock_outline,
                obscureText: _obscureText,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                onFieldSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authInkFaint,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ],
          ),
        ),
        _buildInlineMessage(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: authWine,
                    side: const BorderSide(
                      color: Color(0xFFDCD6CC),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recordarme',
                  style: GoogleFonts.manrope(
                    color: authInkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                _recoveryCorreoCtrl.text = _correoCtrl.text;
                setState(() => _screenState = AuthScreenState.paso1Correo);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
              ),
              child: Text(
                'Olvidaste tu contrasena?',
                style: GoogleFonts.manrope(
                  color: authWine,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        AuthSubmitButton(
          label: 'Ingresar a mi panel',
          loading: _isLoading,
          onPressed: _login,
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFF0EBE1), height: 1),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Todavia no tienes cuenta? ',
              style: GoogleFonts.manrope(
                color: authInkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SolicitudRegistroScreen(),
                ),
              ),
              child: Text(
                'Registra tu restaurante',
                style: GoogleFonts.manrope(
                  color: authWine,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecoveryHeader(
    int step, {
    required VoidCallback onBack,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: authInkSoft,
            ),
            label: Text(
              step == 1 ? 'Volver al login' : 'Volver',
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
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: authInkSoft,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaso1() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecoveryHeader(
            1,
            onBack: () => setState(() => _screenState = AuthScreenState.login),
            title: 'Recupera tu contrasena',
            subtitle:
                'Ingresa el correo asociado a tu cuenta y te enviaremos un codigo de verificacion.',
          ),
          AuthLoginField(
            controller: _recoveryCorreoCtrl,
            label: 'Correo electronico',
            hintText: 'tunombre@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Correo invalido' : null,
          ),
          _buildInlineMessage(),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: 'Enviar codigo',
            loading: _isLoading,
            onPressed: _solicitarRecuperacion,
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRecoveryHeader(
          2,
          onBack: () =>
              setState(() => _screenState = AuthScreenState.paso1Correo),
          title: 'Ingresa el codigo',
          subtitle:
              'Enviamos un codigo de 6 digitos a ${_recoveryCorreoCtrl.text}.',
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
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
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
                    style: GoogleFonts.manrope(
                      color: authInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5DCD0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5DCD0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: authWine, width: 2),
                      ),
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
        _buildInlineMessage(),
        const SizedBox(height: 16),
        Text(
          'El codigo vence en 15:00 minutos',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: authInkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        AuthSubmitButton(
          label: 'Verificar codigo',
          loading: _isLoading,
          disabled: _pinCtrls.map((c) => c.text).join().length < 6,
          onPressed: _verificarPin,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No recibiste el codigo? ',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: authInkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: _isLoading ? null : _solicitarRecuperacion,
              child: Text(
                'Reenviar',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: authWine,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _hasMinLength =>
      PasswordPolicy.hasMinimumLength(_nuevaPasswordCtrl.text);
  bool get _hasRegex =>
      PasswordPolicy.hasUppercase(_nuevaPasswordCtrl.text) &&
      PasswordPolicy.hasLowercase(_nuevaPasswordCtrl.text) &&
      PasswordPolicy.hasNumberOrSymbol(_nuevaPasswordCtrl.text);
  bool get _hasMatch =>
      _nuevaPasswordCtrl.text == _confirmPasswordCtrl.text &&
      _nuevaPasswordCtrl.text.isNotEmpty;
  Widget _buildChecklistItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.check_circle_outline,
            color: isValid ? authSage : const Color(0xFFB5A89D),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                color: isValid ? authSage : authInkSoft,
                fontWeight: isValid ? FontWeight.w700 : FontWeight.w500,
              ),
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
            onBack: () =>
                setState(() => _screenState = AuthScreenState.paso2Pin),
            title: 'Crea una nueva contrasena',
            subtitle: 'Elige una contrasena segura que no hayas usado antes.',
          ),
          AuthLoginField(
            controller: _nuevaPasswordCtrl,
            label: 'Nueva contrasena',
            hintText: 'Escribe tu nueva contrasena',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
            validator: PasswordPolicy.validate,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRecoveryText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: authInkFaint,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureRecoveryText = !_obscureRecoveryText),
            ),
          ),
          const SizedBox(height: 24),
          AuthLoginField(
            controller: _confirmPasswordCtrl,
            label: 'Confirmar contrasena',
            hintText: 'Vuelve a escribir la contrasena',
            icon: Icons.lock_outline,
            obscureText: _obscureRecoveryText,
            validator: (value) => PasswordPolicy.validateConfirmation(
              _nuevaPasswordCtrl.text,
              value,
            ),
          ),
          const SizedBox(height: 24),
          _buildChecklistItem('Al menos 8 caracteres', _hasMinLength),
          _buildChecklistItem(
            'Incluye mayuscula, minuscula y un numero o simbolo',
            _hasRegex,
          ),
          _buildChecklistItem('Las contrasenas coinciden', _hasMatch),
          _buildInlineMessage(),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: 'Guardar contrasena',
            loading: _isLoading,
            onPressed: _restablecerPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildExito() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: authInk.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: authSage.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: authSage,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Contrasena actualizada!',
            style: GoogleFonts.piazzolla(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: authInk,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ya puedes iniciar sesion con tu nueva contrasena.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: authInkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: 'Volver a iniciar sesion',
            loading: false,
            onPressed: () {
              _correoCtrl.text = _recoveryCorreoCtrl.text;
              _passwordCtrl.clear();
              _nuevaPasswordCtrl.clear();
              _confirmPasswordCtrl.clear();
              for (var c in _pinCtrls) {
                c.clear();
              }
              setState(() => _screenState = AuthScreenState.login);
            },
          ),
        ],
      ),
    );
  }
}
