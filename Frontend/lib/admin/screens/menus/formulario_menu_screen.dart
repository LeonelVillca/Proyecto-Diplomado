import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../movil/providers/auth_provider.dart';
import '../../models/menu_admin_model.dart';
import '../../services/menu_admin_service.dart';
import 'dart:html' as html;
import 'dart:typed_data';

class FormularioMenuScreen extends StatefulWidget {
  final int idRestaurante;
  final MenuAdminModel? menuExistente;

  const FormularioMenuScreen({super.key, required this.idRestaurante, this.menuExistente});

  @override
  State<FormularioMenuScreen> createState() => _FormularioMenuScreenState();
}

class _FormularioMenuScreenState extends State<FormularioMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoCtrl;
  
  List<Map<String, dynamic>> _platos = [];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.menuExistente?.nombre ?? '');
    _tipoCtrl = TextEditingController(text: widget.menuExistente?.tipo ?? '');
    
    if (widget.menuExistente != null) {
      _platos = widget.menuExistente!.platos.map((p) => {
        'nombreCtrl': TextEditingController(text: p.nombre),
        'descCtrl': TextEditingController(text: p.descripcion),
        'precioCtrl': TextEditingController(text: p.precio.toString()),
        'fotoUrl': p.fotoUrl,
        'bytes': null,
      }).toList();
    } else {
      _agregarPlato();
    }
  }

  void _agregarPlato() {
    setState(() {
      _platos.add({
        'nombreCtrl': TextEditingController(),
        'descCtrl': TextEditingController(),
        'precioCtrl': TextEditingController(),
        'fotoUrl': null,
        'bytes': null,
      });
    });
  }

  void _quitarPlato(int index) {
    setState(() {
      _platos.removeAt(index);
    });
  }

  Future<void> _seleccionarFoto(int index) async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _platos[index]['bytes'] = reader.result as Uint8List;
            _platos[index]['filename'] = file.name;
          });
        });
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token!;
      final service = MenuAdminService(token);

      // Subir fotos primero
      for (var p in _platos) {
        if (p['bytes'] != null) {
          final url = await service.subirFotoPlato(p['bytes'], p['filename'] ?? 'foto.jpg', widget.idRestaurante);
          p['fotoUrl'] = url;
        }
      }

      final platosData = _platos.map((p) => {
        'nombre': p['nombreCtrl'].text.trim(),
        'descripcion': p['descCtrl'].text.trim(),
        'precio': double.tryParse(p['precioCtrl'].text.trim()) ?? 0.0,
        'fotoUrl': p['fotoUrl'],
      }).toList();

      final data = {
        'idRestaurante': widget.idRestaurante,
        'nombre': _nombreCtrl.text.trim(),
        'tipo': _tipoCtrl.text.trim(),
        'platos': platosData,
      };

      if (widget.menuExistente == null) {
        await service.crearMenu(data);
      } else {
        await service.actualizarMenu(widget.menuExistente!.id, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menú guardado exitosamente')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error al guardar menú: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E1E39)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.menuExistente == null ? 'Crear Nuevo Menú' : 'Modificar Menú',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFF2D0A14), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39)))
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campos Generales del Menú', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Menú (Ej: Menú Ejecutivo)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tipoCtrl,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Menú (Ej: Almuerzo, Cena)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text('Platillos del Menú', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14))),
                  const SizedBox(height: 16),
                  
                  ...List.generate(_platos.length, (index) => _buildPlatoCard(index)),
                  
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _agregarPlato,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text('Agregue otro platillo al menú', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6E1E39),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF6B635E))),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E1E39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Guardar Menú', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPlatoCard(int index) {
    final plato = _platos[index];
    final bool hasImage = plato['bytes'] != null || plato['fotoUrl'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          InkWell(
            onTap: () => _seleccionarFoto(index),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                image: plato['bytes'] != null 
                  ? DecorationImage(image: MemoryImage(plato['bytes'] as Uint8List), fit: BoxFit.cover)
                  : plato['fotoUrl'] != null
                    ? DecorationImage(image: NetworkImage(plato['fotoUrl']), fit: BoxFit.cover)
                    : null,
              ),
              child: !hasImage 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Color(0xFFA39C98)),
                      SizedBox(height: 8),
                      Text('Foto', style: TextStyle(color: Color(0xFFA39C98), fontSize: 12)),
                    ],
                  )
                : null,
            ),
          ),
          const SizedBox(width: 24),
          // Campos
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: plato['nombreCtrl'],
                        decoration: const InputDecoration(labelText: 'Nombre del Platillo', isDense: true),
                        validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: plato['precioCtrl'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio (Bs)', isDense: true),
                        validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null ? 'Válido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: plato['descCtrl'],
                  decoration: const InputDecoration(labelText: 'Descripción corta', isDense: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C)),
            onPressed: () => _quitarPlato(index),
            tooltip: 'Quitar platillo',
          ),
        ],
      ),
    );
  }
}
