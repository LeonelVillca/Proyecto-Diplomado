import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

gestion_menus_content = """import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../movil/providers/auth_provider.dart';
import '../../models/menu_admin_model.dart';
import '../../services/menu_admin_service.dart';
import 'formulario_menu_screen.dart';
import 'detalles_menu_screen.dart';

class GestionMenusScreen extends StatefulWidget {
  const GestionMenusScreen({super.key});

  @override
  State<GestionMenusScreen> createState() => _GestionMenusScreenState();
}

class _GestionMenusScreenState extends State<GestionMenusScreen> {
  bool _isLoading = true;
  List<MenuAdminModel> _menus = [];
  String _filtroTexto = '';
  String _filtroEstado = 'todos'; // todos, activos, inactivos
  int? _idRestaurante;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_idRestaurante == null) {
      _cargarDatos();
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final service = MenuAdminService(token);
      _idRestaurante = await service.obtenerIdRestaurante();
      
      if (_idRestaurante != null) {
        _menus = await service.obtenerMenus(_idRestaurante!);
      }
    } catch (e) {
      debugPrint('Error: \\$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando menús')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarDisponibilidad(MenuAdminModel menu, bool nuevoEstado) async {
    // Optimistic Update
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
      final token = AuthScope.of(context, listen: false).token;
      await MenuAdminService(token).cambiarDisponibilidad(menu.id, nuevoEstado);
    } catch (e) {
      debugPrint('Error: \\$e');
      setState(() => _menus = original);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar disponibilidad')));
    }
  }

  void _abrirFormulario({MenuAdminModel? menu}) async {
    if (_idRestaurante == null) return;
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioMenuScreen(idRestaurante: _idRestaurante!, menuExistente: menu),
      ),
    );
    if (refresh == true) {
      _cargarDatos();
    }
  }

  void _verDetalles(MenuAdminModel menu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallesMenuScreen(menu: menu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _menus.where((m) {
      if (_filtroEstado == 'activos' && !m.disponibilidad) return false;
      if (_filtroEstado == 'inactivos' && m.disponibilidad) return false;
      if (_filtroTexto.isNotEmpty && !m.nombre.toLowerCase().contains(_filtroTexto.toLowerCase())) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Superior
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestión de Menús', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14))),
                const SizedBox(height: 6),
                Text('Crea, edita y organiza tus menús y platillos.', style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B635E))),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Crear Nuevo Menú', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E1E39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Barra de Herramientas
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                onChanged: (val) => setState(() => _filtroTexto = val),
                style: GoogleFonts.manrope(),
                decoration: InputDecoration(
                  hintText: 'Buscar menú...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B635E)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _filtroEstado,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A)),
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos los Estados')),
                  DropdownMenuItem(value: 'activos', child: Text('Solo Activos')),
                  DropdownMenuItem(value: 'inactivos', child: Text('Solo Inactivos')),
                ],
                onChanged: (val) => setState(() => _filtroEstado = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tabla
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: filtrados.isEmpty 
                    ? Center(child: Text('No hay menús registrados.', style: GoogleFonts.manrope(color: const Color(0xFF6B635E))))
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A)),
                          dataTextStyle: GoogleFonts.manrope(color: const Color(0xFF1E1B1A)),
                          dividerThickness: 0.5,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Nombre del Menú')),
                            DataColumn(label: Text('Platillos')),
                            DataColumn(label: Text('Tipo de Menú')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Editar')),
                            DataColumn(label: Text('Habilitar / Ocultar')),
                          ],
                          rows: filtrados.map((m) {
                            return DataRow(cells: [
                              DataCell(Text('#\\${m.id}')),
                              DataCell(Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(
                                TextButton.icon(
                                  onPressed: () => _verDetalles(m),
                                  icon: const Icon(Icons.restaurant_menu, size: 16, color: Color(0xFF6E1E39)),
                                  label: Text('\\${m.platos.length} platos', style: const TextStyle(color: Color(0xFF6E1E39))),
                                ),
                              ),
                              DataCell(Text(m.tipo)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: m.disponibilidad ? const Color(0xFF2ECC71).withValues(alpha: 0.1) : const Color(0xFFE74C3C).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    m.disponibilidad ? 'ACTIVO' : 'INACTIVO',
                                    style: TextStyle(
                                      color: m.disponibilidad ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF6B635E)),
                                  onPressed: () => _abrirFormulario(menu: m),
                                ),
                              ),
                              DataCell(
                                Switch(
                                  value: m.disponibilidad,
                                  activeColor: const Color(0xFF6E1E39),
                                  onChanged: (val) => _cambiarDisponibilidad(m, val),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                ),
        ),
      ],
    );
  }
}
"""

write_file('d:/Proyecto_Diplomado/Frontend/lib/admin/screens/menus/gestion_menus_screen.dart', gestion_menus_content)
