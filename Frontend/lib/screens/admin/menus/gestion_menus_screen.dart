import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/services/admin/menu_admin_service.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/widgets/admin/menus/menu_card.dart';
import 'package:frontend/widgets/admin/menus/menu_design.dart';
import 'detalles_menu_screen.dart';
import 'formulario_menu_screen.dart';

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
        throw StateError(
          'No se encontró un restaurante asociado a esta cuenta.',
        );
      }
      _menus = await service.obtenerMenus(_idRestaurante!);
    } catch (e) {
      debugPrint('Error: $e');
      _loadError = 'No fue posible cargar los menús. Intente nuevamente.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarDisponibilidad(
    MenuAdminModel menu,
    bool nuevoEstado,
  ) async {
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
        if (_selectedMenu?.id == menu.id) _selectedMenu = _menus[index];
      }
    });
    try {
      final token = AuthScope.of(context, listen: false).token!;
      await MenuAdminService(token).cambiarDisponibilidad(menu.id, nuevoEstado);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _menus = original;
        if (_selectedMenu?.id == menu.id) _selectedMenu = menu;
      });
      if (mounted) {
        AdminNotificationModal.error(
          context,
          'No pudimos cambiar la disponibilidad.',
        );
      }
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
        onVisibilityChanged: (visible) =>
            _cambiarDisponibilidad(_selectedMenu!, visible),
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
      if (_filtroTexto.isNotEmpty &&
          !m.nombre.toLowerCase().contains(_filtroTexto.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final horizontal = constraints.maxWidth < 600 ? 0.0 : 32.0;
        final heading = const MenuPageHeading(
          before: 'Gestión de ',
          emphasis: 'Menús.',
          kicker: 'Tu restaurante',
          subtitle: 'Crea, edita y organiza tus menús y platillos.',
        );
        final create = MenuPrimaryButton(
          label: 'Crear nuevo menú',
          icon: Icons.add,
          onPressed: () => _abrirFormulario(),
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 18), create],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 20),
                    create,
                  ],
                ),
              const SizedBox(height: 24),
              _MenuToolbar(
                compact: compact,
                selected: _filtroEstado,
                menus: _menus,
                onSearch: (val) => setState(() => _filtroTexto = val),
                onFilter: (val) => setState(() => _filtroEstado = val),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: MenuDesign.accent,
                        ),
                      )
                    : _loadError != null
                    ? _MenuMessage(
                        icon: Icons.error_outline,
                        title: _loadError!,
                        description: '',
                        action: 'Reintentar',
                        onPressed: _cargarDatos,
                      )
                    : filtrados.isEmpty
                    ? _MenuMessage(
                        icon: Icons.menu_book_outlined,
                        title: _menus.isEmpty
                            ? 'No existen menús registrados.'
                            : 'No se encontraron menús con los filtros actuales.',
                        description: _menus.isEmpty
                            ? 'Crea tu primer menú para mostrar tus platillos.'
                            : 'Prueba otra búsqueda o cambia el filtro.',
                        action: _menus.isEmpty ? 'Crear nuevo menú' : null,
                        onPressed: _menus.isEmpty
                            ? () => _abrirFormulario()
                            : null,
                      )
                    : LayoutBuilder(
                        builder: (context, grid) {
                          final columns = ((grid.maxWidth + 18) / 348)
                              .floor()
                              .clamp(1, 4);
                          return GridView.builder(
                            itemCount: filtrados.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  mainAxisExtent: 310,
                                ),
                            itemBuilder: (context, index) {
                              final menu = filtrados[index];
                              return MenuCard(
                                index: index,
                                menu: menu,
                                onView: () => _verDetalles(menu),
                                onEdit: () => _verDetalles(menu),
                                onVisibilityChanged: (visible) =>
                                    _cambiarDisponibilidad(menu, visible),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuToolbar extends StatelessWidget {
  const _MenuToolbar({
    required this.compact,
    required this.selected,
    required this.menus,
    required this.onSearch,
    required this.onFilter,
  });
  final bool compact;
  final String selected;
  final List<MenuAdminModel> menus;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final search = SizedBox(
      height: 48,
      child: TextField(
        onChanged: onSearch,
        style: MenuDesign.body(13.5, color: MenuDesign.ink),
        decoration: InputDecoration(
          hintText: 'Buscar menú...',
          prefixIcon: const Icon(Icons.search, size: 19),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: MenuDesign.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: MenuDesign.accent, width: 1.5),
          ),
        ),
      ),
    );
    final filters = Container(
      padding: const EdgeInsets.all(4),
      decoration: MenuDesign.card(radius: 999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('todos', 'Todos', Icons.apps_outlined, menus.length),
          _chip(
            'activos',
            'Visibles',
            Icons.visibility_outlined,
            menus.where((m) => m.disponibilidad).length,
          ),
          _chip(
            'inactivos',
            'Ocultos',
            Icons.visibility_off_outlined,
            menus.where((m) => !m.disponibilidad).length,
          ),
        ],
      ),
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filters,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              filters,
            ],
          );
  }

  Widget _chip(String value, String label, IconData icon, int count) {
    final active = selected == value;
    return InkWell(
      onTap: () => onFilter(value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? MenuDesign.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : MenuDesign.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: MenuDesign.body(
                12,
                color: active ? Colors.white : MenuDesign.ink,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: .2)
                    : MenuDesign.cream,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: MenuDesign.body(
                  10,
                  color: active ? Colors.white : MenuDesign.muted,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuMessage extends StatelessWidget {
  const _MenuMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String description;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: MenuDashedBox(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MenuDesign.accentSoft,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, size: 26, color: MenuDesign.accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MenuDesign.title(22),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: MenuDesign.body(13),
              ),
            ],
            if (action != null && onPressed != null) ...[
              const SizedBox(height: 18),
              MenuPrimaryButton(
                label: action!,
                icon: Icons.add,
                onPressed: onPressed,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
