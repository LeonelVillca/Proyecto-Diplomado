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

class AsignacionRolesScreen extends StatefulWidget {
  const AsignacionRolesScreen({super.key});

  @override
  State<AsignacionRolesScreen> createState() => _AsignacionRolesScreenState();
}

class _AsignacionRolesScreenState extends State<AsignacionRolesScreen> {
  bool _isLoading = true;
  List<UsuarioAdminModel> _usuarios = [];
  List<RolModel> _rolesDisponibles = [];
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
      
      // 1. Cargar Usuarios
      final urlUsuarios = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuarios');
      final resUsuarios = await http.get(urlUsuarios, headers: {'Authorization': 'Bearer $token'});
      
      // 2. Cargar Roles
      final urlRoles = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/roles');
      final resRoles = await http.get(urlRoles, headers: {'Authorization': 'Bearer $token'});

      if (resUsuarios.statusCode == 200 && resRoles.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(utf8.decode(resUsuarios.bodyBytes));
        final List<dynamic> rolesData = jsonDecode(utf8.decode(resRoles.bodyBytes));
        
        setState(() {
          _usuarios = usersData.map((e) => UsuarioAdminModel.fromJson(e)).toList();
          _rolesDisponibles = rolesData.map((e) => RolModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuarios/roles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _administrarRoles(UsuarioAdminModel usuario) async {
    final token = AuthScope.of(context).token;
    
    // 1. Obtener roles actuales del usuario
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol/usuario/${usuario.id}');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (!mounted) return;
      Navigator.pop(context); // cerrar loader

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        // data es una lista de objetos UsuarioRol donde { idRol: X, rol: { ... } }
        // Simplificamos obteniendo la lista de IDs de roles que ya tiene el usuario.
        final Set<int> rolesActuales = data.map<int>((ur) {
          return (ur['rol']?['id'] as int?) ?? ur['idRol'] as int;
        }).toSet();

        if (mounted) {
          _mostrarModalRoles(usuario, rolesActuales);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error: $e');
    }
  }

  void _mostrarModalRoles(UsuarioAdminModel usuario, Set<int> rolesAsignados) {
    Set<int> rolesModificados = Set.from(rolesAsignados);

    AdminModal.show(
      context: context,
      title: 'Roles: ${usuario.nombre} ${usuario.apellido ?? ''}'.trim(),
      width: 500,
      confirmText: 'Guardar Cambios',
      onConfirm: () {
        Navigator.pop(context);
        _guardarRoles(usuario.id, rolesAsignados, rolesModificados);
      },
      content: StatefulBuilder(
        builder: (context, setStateModal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Habilita o deshabilita los roles para este usuario. Los cambios tendrán efecto inmediato tras guardar.',
                style: GoogleFonts.inter(color: const Color(0xFF6B635E), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ..._rolesDisponibles.map((rol) {
                final hasRole = rolesModificados.contains(rol.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: hasRole ? const Color(0xFF6E1E39).withOpacity(0.04) : Colors.white,
                    border: Border.all(
                      color: hasRole ? const Color(0xFF6E1E39).withOpacity(0.3) : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      activeColor: const Color(0xFF6E1E39),
                    title: Text(rol.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E1B1A))),
                    subtitle: Text(rol.descripcion ?? 'Sin descripción', style: GoogleFonts.inter(color: const Color(0xFFA39C98), fontSize: 13)),
                    value: hasRole,
                    onChanged: (val) {
                      setStateModal(() {
                        if (val) rolesModificados.add(rol.id);
                        else rolesModificados.remove(rol.id);
                      });
                    },
                  ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarRoles(int idUsuario, Set<int> rolesViejos, Set<int> rolesNuevos) async {
    final token = AuthScope.of(context).token;
    
    final rolesParaAgregar = rolesNuevos.difference(rolesViejos);
    final rolesParaQuitar = rolesViejos.difference(rolesNuevos);

    try {
      // 1. Agregar nuevos
      for (final idRol in rolesParaAgregar) {
        await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'idUsuario': idUsuario, 'idRol': idRol}),
        );
      }
      // 2. Quitar removidos
      for (final idRol in rolesParaQuitar) {
        await http.delete(
          Uri.parse('${ApiEndpoints.baseUrl}/api/v1/usuario-rol/usuario/$idUsuario/rol/$idRol'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      if (mounted) {
        AdminNotificationModal.success(context, 'Roles actualizados correctamente');
      }
    } catch (e) {
      debugPrint('Error actualizando roles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado
    List<UsuarioAdminModel> filtrados = _usuarios.where((u) {
      final matchText = _searchQuery.isEmpty || 
          u.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          (u.apellido ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) || 
          u.correo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchText;
    }).toList();

    // Paginación
    final totalItems = filtrados.length;
    final totalPages = math.max(1, (totalItems / _itemsPerPage).ceil());
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, totalItems);
    final paginatedUsuarios = startIndex < totalItems ? filtrados.sublist(startIndex, endIndex) : <UsuarioAdminModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Cabecera y Botón
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignación de Roles',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Asigna los roles del sistema a los usuarios.',
                  style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Barra de Filtros
        Row(
          children: [
            Container(
              width: 400,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFA39C98), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                      style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1E1B1A)),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, correo...',
                        hintStyle: GoogleFonts.manrope(color: const Color(0xFFA39C98)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filtroEstado,
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.keyboard_arrow_down, color: Color(0xFFA39C98), size: 20),
                  ),
                  style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A), fontSize: 14, fontWeight: FontWeight.w600),
                  items: ['Todos', 'Activos', 'Inactivos'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() { _filtroEstado = v!; _currentPage = 1; }),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Tabla Corporativa
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Cabeceras (th)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('USUARIO', style: _headerStyle())),
                      Expanded(flex: 2, child: Text('CORREO', style: _headerStyle())),
                      Expanded(flex: 1, child: Text('ROLES', style: _headerStyle())),
                      SizedBox(width: 120, child: Text('ACCIONES', style: _headerStyle(), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // Filas
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
                      : paginatedUsuarios.isEmpty
                          ? Center(child: Text('No se encontraron usuarios', style: GoogleFonts.manrope(color: const Color(0xFFA39C98))))
                          : ListView.builder(
                              itemCount: paginatedUsuarios.length,
                              itemBuilder: (context, index) {
                                final user = paginatedUsuarios[index];
                                return _buildTableRow(user, index < paginatedUsuarios.length - 1);
                              },
                            ),
                ),
                // 4. Paginador Estándar
                if (totalItems > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mostrando ${startIndex + 1}â€“$endIndex de $totalItems',
                          style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 13),
                        ),
                        Row(
                          children: [
                            _buildPageBtn('Anterior', _currentPage > 1 ? () => setState(() => _currentPage--) : null),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                int startPage = math.max(1, _currentPage - 2);
                                int endPage = math.min(totalPages, startPage + 4);
                                if (endPage - startPage < 4) {
                                  startPage = math.max(1, endPage - 4);
                                }
                                return Row(
                                  children: List.generate(endPage - startPage + 1, (i) {
                                    final page = startPage + i;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: _buildPageNum(page, _currentPage == page),
                                    );
                                  }),
                                );
                              }
                            ),
                            const SizedBox(width: 8),
                            _buildPageBtn('Siguiente', _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle() => GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFA39C98), letterSpacing: 1);

  Widget _buildTableRow(UsuarioAdminModel user, bool showDivider) {
    return _TableRowHover(
      showDivider: showDivider,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFCF4F7),
                  foregroundColor: const Color(0xFF6E1E39),
                  child: Text(user.nombre[0].toUpperCase(), style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${user.nombre} ${user.apellido ?? ''}'.trim(),
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: const Color(0xFF1E1B1A), fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.correo,
              style: GoogleFonts.manrope(color: const Color(0xFF6B635E), fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => _administrarRoles(user),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(50)),
                    child: Text('Ver roles', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6B635E))),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionIcon(icon: Icons.manage_accounts_outlined, onTap: () => _administrarRoles(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn(String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(text, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: onTap == null ? const Color(0xFFD1D5DB) : const Color(0xFF1E1B1A))),
      ),
    );
  }

  Widget _buildPageNum(int page, bool isActive) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6E1E39) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          page.toString(),
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : const Color(0xFF6B635E)),
        ),
      ),
    );
  }
}

class _TableRowHover extends StatefulWidget {
  final Widget child;
  final bool showDivider;
  const _TableRowHover({required this.child, required this.showDivider});

  @override
  State<_TableRowHover> createState() => _TableRowHoverState();
}

class _TableRowHoverState extends State<_TableRowHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FAFC) : Colors.white,
          border: widget.showDivider ? const Border(bottom: BorderSide(color: Color(0xFFF0F2F5))) : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final bool isDanger;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap, this.isDanger = false});

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDanger 
        ? (_hover ? Colors.white : const Color(0xFFEF4444)) 
        : (_hover ? const Color(0xFF6E1E39) : const Color(0xFF6B635E));
    final bg = widget.isDanger
        ? (_hover ? const Color(0xFFEF4444) : const Color(0xFFFEF2F2))
        : (_hover ? const Color(0xFFFCF4F7) : const Color(0xFFF0F2F5));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 16, color: fg),
        ),
      ),
    );
  }
}



