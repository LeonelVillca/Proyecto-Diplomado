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

part 'inicio_sesion_admin/servicio_autenticacion_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/mensaje_acceso_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/selector_estado_login_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/formulario_acceso_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/encabezado_recuperacion_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/paso_correo_recuperacion_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/paso_verificacion_pin_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/paso_nueva_contrasena_admin.dart';
part '../../../widgets/admin/inicio_sesion_admin/confirmacion_recuperacion_admin.dart';

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
                          child: ContenidoEstadoLoginAdmin(pantalla: this),
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
}
