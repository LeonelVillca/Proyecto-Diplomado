import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/services/admin/menu_admin_service.dart';
import 'formulario_menu_screen.dart';
import 'detalles_menu_screen.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

const Color kBurgundy900 = Color(0xFF26201A);
const Color kBurgundy700 = Color(0xFFBE4B24);
const Color kBurgundy600 = Color(0xFF9E3A18);
const Color kBurgundy100 = Color(0xFFF8E7DC);
const Color kCream = Color(0xFFFAF5EC);
const Color kCard = Color(0xFFFFFFFF);
const Color kLine = Color(0xFFEAE1D3);
const Color kInk = Color(0xFF26201A);
const Color kInkSoft = Color(0xFF6F6259);
const Color kGreen = Color(0xFF1F7A4D);
const Color kGreenBg = Color(0xFFE3F1E8);

final List<BoxShadow> kShadow = [
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.07), blurRadius: 28, offset: const Offset(0, 10)),
];

enum _MenuViewState { list, detail, form }

class GestionMenusScreen extends StatefulWidget {
  const GestionMenusScreen({super.key});

  @override
  State<GestionMenusScreen> createState() => _GestionMenusScreenState();
}

class _GestionMenusScreenState extends State<GestionMenusScreen> {
  bool _isLoading = true;
  bool _initialLoadStarted = false;
  List<MenuAdminModel> _menus = [];
  String? _loadError;
  String _filtroTexto = '';
  String _filtroEstado = 'todos'; 
  int? _idRestaurante;

  _MenuViewState _currentView = _MenuViewState.list;
  MenuAdminModel? _selectedMenu;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      _cargarDatos();
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final token = AuthScope.of(context, listen: false).token!;
      final service = MenuAdminService(token);
      _idRestaurante = await service.obtenerIdRestaurante();
      if (_idRestaurante == null) {
        throw StateError('No se encontró un restaurante asociado a esta cuenta.');
      }
      _menus = await service.obtenerMenus(_idRestaurante!);
    } catch (e) {
      debugPrint('Error: $e');
      _loadError = 'No fue posible cargar los menús. Intente nuevamente.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarDisponibilidad(MenuAdminModel menu, bool nuevoEstado) async {
    final original = List<MenuAdminModel>.from(_menus);
    setState(() {
      final index = _menus.indexWhere((m) => m.id == menu.id);
      if (index != -1) {
        _menus[index] = MenuAdminModel(
          id: menu.id,
          idRestaurante: menu.idRestaurante,
          nombre: menu.nombre,
          tipo: menu.tipo,
          disponibilidad: nuevoEstado,
          platos: menu.platos,
        );
      }
    });

    try {
      final token = AuthScope.of(context, listen: false).token!;
      await MenuAdminService(token).cambiarDisponibilidad(menu.id, nuevoEstado);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _menus = original);
      if (mounted) AdminNotificationModal.error(context, 'No pudimos cambiar la disponibilidad.');
    }
  }

  void _abrirFormulario({MenuAdminModel? menu}) {
    if (_idRestaurante == null) return;
    setState(() {
      _selectedMenu = menu;
      _currentView = _MenuViewState.form;
    });
  }

  void _verDetalles(MenuAdminModel menu) {
    setState(() {
      _selectedMenu = menu;
      _currentView = _MenuViewState.detail;
    });
  }

  void _volverALista() {
    setState(() {
      _currentView = _MenuViewState.list;
      _selectedMenu = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == _MenuViewState.detail && _selectedMenu != null) {
      return DetallesMenuScreen(
        menu: _selectedMenu!,
        onBack: _volverALista,
        onEdit: () => _abrirFormulario(menu: _selectedMenu),
      );
    }

    if (_currentView == _MenuViewState.form && _idRestaurante != null) {
      return FormularioMenuScreen(
        idRestaurante: _idRestaurante!,
        menuExistente: _selectedMenu,
        onBack: _volverALista,
        onSaved: () {
          _volverALista();
          _cargarDatos();
        },
      );
    }

    final filtrados = _menus.where((m) {
      if (_filtroEstado == 'activos' && !m.disponibilidad) return false;
      if (_filtroEstado == 'inactivos' && m.disponibilidad) return false;
      if (_filtroTexto.isNotEmpty && !m.nombre.toLowerCase().contains(_filtroTexto.toLowerCase())) return false;
      return true;
    }).toList();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildToolbar(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kBurgundy700))
                : _loadError != null
                    ? _buildLoadError()
                    : _buildTable(filtrados),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(18),
        boxShadow: kShadow,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                style: GoogleFonts.manrope(fontSize: 13.5, color: kInkSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh, color: kBurgundy700),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.manrope(
                    color: kBurgundy700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de menús', style: GoogleFonts.instrumentSerif(fontSize: 32, fontWeight: FontWeight.w400, color: kBurgundy900, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text('Crea, edita y organiza tus menús y platillos.', style: GoogleFonts.manrope(fontSize: 14, color: kInkSoft)),
          ],
        ),
        InkWell(
          onTap: () => _abrirFormulario(),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBurgundy600, kBurgundy900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: kBurgundy700.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Crear nuevo menú', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kCard,
              border: Border.all(color: kLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: kInkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _filtroTexto = val),
                    style: GoogleFonts.manrope(fontSize: 13.5, color: kInk),
                    decoration: InputDecoration(
                      hintText: 'Buscar menú...',
                      hintStyle: GoogleFonts.manrope(fontSize: 13.5, color: kInkSoft),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kCard,
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtroEstado,
              icon: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.keyboard_arrow_down, size: 18, color: kInk),
              ),
              isDense: true,
              style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: kInk),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos los estados')),
                DropdownMenuItem(value: 'activos', child: Text('Solo activos')),
                DropdownMenuItem(value: 'inactivos', child: Text('Solo inactivos')),
              ],
              onChanged: (val) => setState(() => _filtroEstado = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<MenuAdminModel> filtrados) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(18),
        boxShadow: kShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: kCard,
              border: Border(bottom: BorderSide(color: kLine)),
            ),
            child: Row(
              children: [
                Expanded(flex: 24, child: Text('MENÚ', style: _headerStyle())),
                Expanded(flex: 10, child: Text('TIPO', style: _headerStyle())),
                Expanded(flex: 10, child: Text('ESTADO', style: _headerStyle())),
                Expanded(flex: 10, child: Text('EDITAR', style: _headerStyle())),
                Expanded(flex: 6, child: Align(alignment: Alignment.centerRight, child: Text('VISIBLE', style: _headerStyle()))),
              ],
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                    child: Text(
                      _menus.isEmpty
                          ? 'No existen menús registrados.'
                          : 'No se encontraron menús con los filtros actuales.',
                      style: GoogleFonts.manrope(fontSize: 13.5, color: kInkSoft),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => Container(height: 1, color: kLine),
                  itemBuilder: (context, index) {
                    final m = filtrados[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 24,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: kBurgundy100, borderRadius: BorderRadius.circular(11)),
                                  child: const Icon(Icons.menu_book, color: kBurgundy700, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.nombre, style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.bold, color: kInk), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('#${m.id} · ${m.platos.length} platillo${m.platos.length == 1 ? '' : 's'}', style: GoogleFonts.manrope(fontSize: 12, color: kInkSoft)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: Text(m.tipo, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
                          ),
                          Expanded(
                            flex: 10,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: m.disponibilidad ? kGreenBg : kLine.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: m.disponibilidad ? kGreen : kInkSoft),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(m.disponibilidad ? 'Activo' : 'Inactivo', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.bold, color: m.disponibilidad ? kGreen : kInkSoft)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 10,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => _verDetalles(m),
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(color: kCard, border: Border.all(color: kLine), borderRadius: BorderRadius.circular(9)),
                                  child: const Icon(Icons.edit_outlined, color: kBurgundy700, size: 18),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _cambiarDisponibilidad(m, !m.disponibilidad),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 42,
                                  height: 24,
                                  decoration: BoxDecoration(color: m.disponibilidad ? kGreen : kLine, borderRadius: BorderRadius.circular(99)),
                                  padding: const EdgeInsets.all(3),
                                  alignment: m.disponibilidad ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: kInkSoft);
  }
}
