import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/usuario_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool _isLoading = true;
  List<UsuarioAdminModel> _usuarios = [];
  bool _isInit = true;

  String _searchQuery = '';
  String _filtroEstado = 'Todos';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarDatosIniciales();
      _isInit = false;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final token = AuthScope.of(context).token;
      final urlUsuarios = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuarios');
      final resUsuarios = await http.get(urlUsuarios, headers: {'Authorization': 'Bearer $token'});

      if (resUsuarios.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(utf8.decode(resUsuarios.bodyBytes));
        if (mounted) {
          setState(() {
            _usuarios = usersData.map((e) => UsuarioAdminModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDetalles(UsuarioAdminModel user) {
    AdminModal.show(
      context: context,
      title: 'Detalles del Usuario',
      width: 450,
      confirmText: 'Cerrar',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                foregroundColor: AdminTheme.primaryColor,
                child: Text(user.nombre[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${user.nombre} ${user.apellido ?? ''}'.trim(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.textDark)),
                    Text(user.correo, style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.app_registration_rounded, 'Registrado', user.fechaRegistro.isNotEmpty ? user.fechaRegistro.substring(0, 10) : 'Desconocido'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.login_rounded, 'Acceso Local (App Web)', user.esLocal ? 'Habilitado' : 'No Habilitado', color: user.esLocal ? Colors.green : AdminTheme.textMuted),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.g_mobiledata_rounded, 'Acceso Externo (Google)', user.esExterno ? 'Vinculado' : 'No Vinculado', color: user.esExterno ? Colors.blue : AdminTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AdminTheme.textMuted),
        const SizedBox(width: 12),
        Text('$label: ', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 14)),
        Expanded(child: Text(value, style: GoogleFonts.inter(color: color ?? AdminTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.right)),
      ],
    );
  }

  void _mostrarCrearUsuario() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    AdminModal.show(
      context: context,
      title: 'Crear Usuario Local',
      width: 500,
      confirmText: 'Crear',
      onConfirm: () async {
        if (formKey.currentState!.validate()) {
          final token = AuthScope.of(context, listen: false).token;
          try {
            final res = await http.post(
              Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuarios/admin-crear'),
              headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
              body: jsonEncode({
                'nombre': nombreCtrl.text,
                'apellido': apellidoCtrl.text,
                'correo': correoCtrl.text,
                'telefono': telefonoCtrl.text,
                'password': passwordCtrl.text,
              }),
            );
            if (res.statusCode == 201) {
              Navigator.pop(context);
              _cargarDatosIniciales();
              AdminNotificationModal.success(context, 'Usuario creado correctamente');
            } else {
              AdminNotificationModal.error(context, 'No pudimos crear el usuario.');
            }
          } catch (e) {
            AdminNotificationModal.error(context, 'Error de conexión. Verifica tu conexión e inténtalo nuevamente.');
          }
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AdminTheme.primaryColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Datos de la cuenta', style: AdminTheme.subtitleStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Completa los campos para crear el acceso local.', style: AdminTheme.bodyStyle.copyWith(fontSize: 13)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Nombre',
                    hint: 'ej. Leonel',
                    controller: nombreCtrl,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Apellido',
                    hint: 'ej. Villca',
                    controller: apellidoCtrl,
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMinimalInput(
              label: 'Correo Electrónico',
              hint: 'ej. leonel.v@empresa.com',
              controller: correoCtrl,
              icon: Icons.mail_outline_rounded,
              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Teléfono',
                    hint: 'ej. +591 71234567',
                    controller: telefonoCtrl,
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Contraseña Provisional',
                    hint: 'Mínimo 6 caracteres',
                    controller: passwordCtrl,
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminTheme.subtitleStyle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark),
          decoration: AdminInputDecoration.get(labelText: label, hintText: hint, prefixIcon: icon),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<UsuarioAdminModel> filtrados = _usuarios.where((u) {
      final matchText = _searchQuery.isEmpty || 
          u.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          (u.apellido ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) || 
          u.correo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchText;
    }).toList();

    final totalItems = filtrados.length;
    final totalPages = math.max(1, (totalItems / _itemsPerPage).ceil());
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, totalItems);
    final paginatedUsuarios = startIndex < totalItems ? filtrados.sublist(startIndex, endIndex) : <UsuarioAdminModel>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            kicker: 'EQUIPO',
            titleBefore: 'Gestión de ',
            titleEmphasis: 'Usuarios',
            description: 'Administra las cuentas, visualiza detalles y orígenes de registro.',
            actions: [
              FilledButton.icon(
                onPressed: _mostrarCrearUsuario,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Nuevo usuario local'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdminSurface(
            padding: const EdgeInsets.all(14),
            radius: AdminTheme.mediumRadius,
            child: AdminSearchField(
              onChanged: (value) => setState(() {
                _searchQuery = value;
                _currentPage = 1;
              }),
              hintText: 'Buscar por nombre o correo...',
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AdminSurface(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AdminTheme.surfaceMuted,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      border: Border(bottom: BorderSide(color: AdminTheme.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('USUARIO', style: _headerStyle())),
                        Expanded(flex: 2, child: Text('CORREO', style: _headerStyle())),
                        Expanded(flex: 1, child: Text('TIPO DE CUENTA', style: _headerStyle())),
                        SizedBox(width: 80, child: Text('ACCIÓN', style: _headerStyle(), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryColor))
                        : ListView.separated(
                            itemCount: paginatedUsuarios.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = paginatedUsuarios[index];
                              return _buildTableRow(user);
                            },
                          ),
                  ),
                  if (totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AdminTheme.border))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mostrando ${startIndex + 1}–$endIndex de $totalItems', style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 13)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              ),
                              Text('$_currentPage / $totalPages', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AdminTheme.textMuted);

  Widget _buildTableRow(UsuarioAdminModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                AdminInitialAvatar(label: '${user.nombre} ${user.apellido ?? ''}', round: true, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${user.nombre} ${user.apellido ?? ''}'.trim(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AdminTheme.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.correo, style: GoogleFonts.inter(color: AdminTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                if (user.esLocal) const Icon(Icons.computer_rounded, size: 16, color: Colors.green),
                if (user.esLocal && user.esExterno) const SizedBox(width: 8),
                if (user.esExterno) const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.blue),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(Icons.visibility_rounded, color: AdminTheme.primaryColor),
                onPressed: () => _mostrarDetalles(user),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
