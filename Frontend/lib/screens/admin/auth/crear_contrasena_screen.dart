import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/screens/admin/auth/admin_login_screen.dart';
import 'package:frontend/screens/admin/auth/auth_response_message.dart';
import 'package:frontend/screens/admin/auth/password_policy.dart';
import 'package:frontend/screens/admin/auth/widgets/auth_components.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;

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
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_refreshPasswordChecklist);
    _confirmCtrl.addListener(_refreshPasswordChecklist);
  }

  void _refreshPasswordChecklist() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearContrasena() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null || widget.token!.isEmpty) {
      setState(
        () => _errorMessage =
            'Este enlace no contiene un código válido. Solicita que te envíen una nueva invitación.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/auth/crear-contrasena'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': widget.token,
          'password': _passwordCtrl.text,
        }),
        timeout: const Duration(seconds: 45),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) setState(() => _isSuccess = true);
      } else {
        final fallback = res.statusCode == 400
            ? 'El enlace ya venció o fue utilizado. Solicita una invitación nueva.'
            : 'No se pudo crear la contraseña. Inténtalo nuevamente.';
        if (mounted) {
          setState(
            () => _errorMessage = authHttpErrorMessage(
              res.statusCode,
              res.body,
              fallback,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'La operación tardó demasiado y no pudimos confirmar el resultado. Prueba iniciar sesión con la contraseña nueva antes de volver a enviar la invitación.',
        );
      }
    } on http.ClientException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo otra vez.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Ocurrió un problema inesperado al guardar. Vuelve a intentarlo; si persiste, solicita una invitación nueva.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authPaper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 480 ? 24 : 44,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: authCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE9E0D1)),
                  boxShadow: [
                    BoxShadow(
                      color: authInk.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: _isSuccess ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: authWine.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 34,
                  color: authWine,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Crea tu contraseña',
              textAlign: TextAlign.center,
              style: GoogleFonts.piazzolla(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: authInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Define una contraseña segura para activar tu cuenta de Mesa Chapaca.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: authInkSoft,
              ),
            ),
            const SizedBox(height: 30),
            AuthLoginField(
              controller: _passwordCtrl,
              label: 'Nueva contraseña',
              hintText: 'Escribe una contraseña segura',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              validator: PasswordPolicy.validate,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: authInkSoft,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AuthLoginField(
              controller: _confirmCtrl,
              label: 'Confirmar contraseña',
              hintText: 'Vuelve a escribirla',
              icon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmation,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => PasswordPolicy.validateConfirmation(
                _passwordCtrl.text,
                value,
              ),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Mostrar confirmación'
                    : 'Ocultar confirmación',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: authInkSoft,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildPasswordChecklist(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_errorMessage!),
            ],
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: 'Guardar contraseña',
              loading: _isLoading,
              onPressed: _crearContrasena,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E0D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu contraseña debe tener:',
            style: GoogleFonts.manrope(
              color: authInk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _checklistItem(
            '8 caracteres como mínimo',
            PasswordPolicy.hasMinimumLength(_passwordCtrl.text),
          ),
          _checklistItem(
            'Una letra mayúscula y una minúscula',
            PasswordPolicy.hasUppercase(_passwordCtrl.text) &&
                PasswordPolicy.hasLowercase(_passwordCtrl.text),
          ),
          _checklistItem(
            'Un número o un símbolo',
            PasswordPolicy.hasNumberOrSymbol(_passwordCtrl.text),
          ),
          _checklistItem(
            'La confirmación debe coincidir',
            _confirmCtrl.text.isNotEmpty &&
                _confirmCtrl.text == _passwordCtrl.text,
          ),
        ],
      ),
    );
  }

  Widget _checklistItem(String label, bool complete) {
    final color = complete ? authSage : authInkSoft;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                height: 1.4,
                color: color,
                fontWeight: complete ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFD95C5C).withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFD95C5C).withValues(alpha: 0.24),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 19,
          color: Color(0xFFB33C3C),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFF8E3030),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: authSage.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 42,
              color: authSage,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Contraseña creada!',
          textAlign: TextAlign.center,
          style: GoogleFonts.piazzolla(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            color: authInk,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu cuenta ya está activa. Inicia sesión con tu nueva contraseña para entrar al panel.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: authInkSoft,
          ),
        ),
        const SizedBox(height: 30),
        AuthSubmitButton(
          label: 'Ir a iniciar sesión',
          loading: false,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          ),
        ),
      ],
    );
  }
}
