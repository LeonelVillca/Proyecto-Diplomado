import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/services/admin/menu_admin_service.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';

const Color kBurgundy900 = Color(0xFF42101F);
const Color kBurgundy700 = Color(0xFF6E1E39);
const Color kBurgundy600 = Color(0xFF872A4C);
const Color kBurgundy100 = Color(0xFFF6E9EE);
const Color kCream = Color(0xFFF7F2EA);
const Color kCard = Color(0xFFFFFFFF);
const Color kLine = Color(0xFFE9E0D1);
const Color kInk = Color(0xFF2A2320);
const Color kInkSoft = Color(0xFF8C8074);
const Color kRed = Color(0xFFC0392B);
const Color kRedBg = Color(0xFFFBEAE7);

final List<BoxShadow> kShadow = [
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.07), blurRadius: 28, offset: const Offset(0, 10)),
];

class FormularioMenuScreen extends StatefulWidget {
  final int idRestaurante;
  final MenuAdminModel? menuExistente;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const FormularioMenuScreen({
    super.key,
    required this.idRestaurante,
    this.menuExistente,
    required this.onBack,
    required this.onSaved,
  });

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
        'nombre': _nombreCtrl.text.trim(),
        'tipo': _tipoCtrl.text.trim(),
        'platos': platosData,
      };

      if (widget.menuExistente == null) {
        data['idRestaurante'] = widget.idRestaurante;
        await service.crearMenu(data);
      } else {
        await service.actualizarMenu(widget.menuExistente!.id, data);
      }

      if (mounted) {
        AdminNotificationModal.success(context, 'Menú guardado exitosamente');
        widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error al guardar menú: $e');
      if (mounted) AdminNotificationModal.error(context, 'Error al guardar el menú. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kBurgundy700))
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 30, 40, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Volver
                  InkWell(
                    onTap: widget.onBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back, size: 16, color: kBurgundy700),
                        const SizedBox(width: 6),
                        Text('Volver a Gestión de menús', style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: kBurgundy700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  Text(
                    widget.menuExistente == null ? 'Crear nuevo menú' : 'Modificar menú',
                    style: GoogleFonts.instrumentSerif(fontSize: 32, fontWeight: FontWeight.w400, color: kBurgundy900, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 24),
                  
                  // Campos Generales
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: kShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campos generales del menú', style: GoogleFonts.instrumentSerif(fontSize: 19, color: kInk)),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInput('Nombre del menú', 'Ej: Menú Ejecutivo', _nombreCtrl)),
                            const SizedBox(width: 18),
                            Expanded(child: _buildInput('Tipo de menú', 'Ej: Almuerzo, Cena', _tipoCtrl)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Platillos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: kShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Platillos del menú', style: GoogleFonts.instrumentSerif(fontSize: 19, color: kInk)),
                        const SizedBox(height: 18),
                        ...List.generate(_platos.length, (index) => _buildPlatoCard(index)),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _agregarPlato,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kBurgundy100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBurgundy600, width: 1.5, style: BorderStyle.none),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: kBurgundy700, size: 18),
                                const SizedBox(width: 8),
                                Text('Agregar otro platillo al menú', style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: kBurgundy700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onBack,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        child: Text('Cancelar', style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: kInkSoft)),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: _guardar,
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              const Icon(Icons.check, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Guardar menú', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: kInkSoft)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.manrope(fontSize: 13.5, color: kInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(fontSize: 13.5, color: const Color(0xFFB7AC9E)),
            filled: true,
            fillColor: const Color(0xFFFDFBF7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kLine, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kLine, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: kBurgundy600, width: 1.5)),
          ),
          validator: (v) => v!.trim().isEmpty ? 'Requerido' : (isNumber && double.tryParse(v) == null ? 'Inválido' : null),
        ),
      ],
    );
  }

  Widget _buildPlatoCard(int index) {
    final plato = _platos[index];
    final bool hasImage = plato['bytes'] != null || plato['fotoUrl'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine, width: 1.5), 
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Selector
              InkWell(
                onTap: () => _seleccionarFoto(index),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: kBurgundy100,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: plato['bytes'] != null
                      ? Image.memory(plato['bytes'] as Uint8List, fit: BoxFit.cover)
                      : plato['fotoUrl'] != null
                          ? Image.network(
                              plato['fotoUrl'].toString().startsWith('/') ? '${ApiEndpoints.baseUrl}${plato['fotoUrl']}' : plato['fotoUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 18),
              // Fields
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildInput('Nombre del platillo', '', plato['nombreCtrl'])),
                        const SizedBox(width: 14),
                        Expanded(flex: 1, child: _buildInput('Precio (Bs)', '0.00', plato['precioCtrl'], isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildInput('Descripción corta', '', plato['descCtrl']),
                  ],
                ),
              ),
              const SizedBox(width: 32), // space for the delete button
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => _quitarPlato(index),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: kRedBg, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.delete_outline, color: kRed, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, color: kBurgundy700, size: 24),
        const SizedBox(height: 6),
        Text('Foto', style: GoogleFonts.manrope(color: kBurgundy700, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
