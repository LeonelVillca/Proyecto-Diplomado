import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/usuario_admin_model.dart';
import 'package:frontend/widgets/admin/admin_modal.dart';
import 'package:frontend/core/admin/theme_admin.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado correctamente')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
          }
        }
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Nombre',
                    hint: 'ej. Leonel',
                    controller: nombreCtrl,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Apellido',
                    hint: 'ej. Villca',
                    controller: apellidoCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMinimalInput(
              label: 'Correo Electrónico',
              hint: 'ej. leonel.v@empresa.com',
              controller: correoCtrl,
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMinimalInput(
                    label: 'Contraseña Provisional',
                    hint: 'Mínimo 6 caracteres',
                    controller: passwordCtrl,
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
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF495057)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.poppins(fontSize: 14, color: AdminTheme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFADB5BD)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AdminTheme.primaryColor),
            ),
          ),
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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Usuarios', style: AdminTheme.titleStyle),
              FilledButton.icon(
                onPressed: _mostrarCrearUsuario,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo Usuario Local'),
                style: FilledButton.styleFrom(backgroundColor: AdminTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Administra las cuentas, visualiza detalles y orígenes de registro.',
            style: GoogleFonts.inter(color: AdminTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textMuted),
                    hintText: 'Buscar por nombre o correo...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
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

  TextStyle _headerStyle() => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted);

  Widget _buildTableRow(UsuarioAdminModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AdminTheme.primaryColor,
                  child: Text(user.nombre[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
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

