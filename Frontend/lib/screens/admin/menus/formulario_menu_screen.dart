import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/services/admin/menu_admin_service.dart';
import 'package:frontend/widgets/admin/admin_notification_modal.dart';
import 'package:frontend/widgets/admin/menus/menu_design.dart';
import 'package:frontend/widgets/admin/menus/menu_form_widgets.dart';
import 'package:universal_html/html.dart' as html;

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
    _nombreCtrl = TextEditingController(
      text: widget.menuExistente?.nombre ?? '',
    );
    _tipoCtrl = TextEditingController(text: widget.menuExistente?.tipo ?? '');
    if (widget.menuExistente != null) {
      _platos = widget.menuExistente!.platos
          .map(
            (p) => {
              'nombreCtrl': TextEditingController(text: p.nombre),
              'descCtrl': TextEditingController(text: p.descripcion),
              'precioCtrl': TextEditingController(text: p.precio.toString()),
              'fotoUrl': p.fotoUrl,
              'bytes': null,
            },
          )
          .toList();
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
          final url = await service.subirFotoPlato(
            p['bytes'],
            p['filename'] ?? 'foto.jpg',
            widget.idRestaurante,
          );
          p['fotoUrl'] = url;
        }
      }
      final platosData = _platos
          .map(
            (p) => {
              'nombre': p['nombreCtrl'].text.trim(),
              'descripcion': p['descCtrl'].text.trim(),
              'precio': double.tryParse(p['precioCtrl'].text.trim()) ?? 0.0,
              'fotoUrl': p['fotoUrl'],
            },
          )
          .toList();
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
      if (mounted) {
        AdminNotificationModal.error(
          context,
          'Error al guardar el menú. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth < 600 ? 0.0 : 32.0;
      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuGhostButton(
                label: 'Volver a Gestión de menús',
                icon: Icons.arrow_back,
                onPressed: widget.onBack,
              ),
              const SizedBox(height: 22),
              MenuPageHeading(
                before: widget.menuExistente == null ? 'Crear ' : 'Modificar ',
                emphasis: widget.menuExistente == null
                    ? 'nuevo menú.'
                    : 'menú.',
                kicker: 'Gestión de menús',
                subtitle: widget.menuExistente == null
                    ? 'Completa los datos generales y agrega los platillos.'
                    : 'Modifica los datos y guarda los cambios.',
              ),
              const SizedBox(height: 24),
              MenuFormSection(
                icon: Icons.menu_book_outlined,
                title: 'Campos generales del menú',
                description:
                    'La información principal que verán tus comensales.',
                child: LayoutBuilder(
                  builder: (context, area) => area.maxWidth < 560
                      ? Column(
                          children: [
                            MenuFormField(
                              label: 'Nombre del menú',
                              hint: 'Ej: Menú Ejecutivo',
                              controller: _nombreCtrl,
                            ),
                            const SizedBox(height: 15),
                            MenuFormField(
                              label: 'Tipo de menú',
                              hint: 'Ej: Almuerzo, Cena',
                              controller: _tipoCtrl,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: MenuFormField(
                                label: 'Nombre del menú',
                                hint: 'Ej: Menú Ejecutivo',
                                controller: _nombreCtrl,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: MenuFormField(
                                label: 'Tipo de menú',
                                hint: 'Ej: Almuerzo, Cena',
                                controller: _tipoCtrl,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              MenuFormSection(
                icon: Icons.restaurant_menu_outlined,
                title: 'Platillos del menú',
                description:
                    '${_platos.length} platillo${_platos.length == 1 ? '' : 's'} en este menú.',
                olive: true,
                child: Column(
                  children: [
                    ...List.generate(
                      _platos.length,
                      (index) => MenuDishEditor(
                        plato: _platos[index],
                        onPhoto: () => _seleccionarFoto(index),
                        onDelete: () => _quitarPlato(index),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: MenuDashedBox(
                        radius: 14,
                        color: MenuDesign.accent,
                        child: OutlinedButton.icon(
                          onPressed: _agregarPlato,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            'Agregar otro platillo al menú',
                            style: MenuDesign.body(
                              13.5,
                              color: MenuDesign.accentDark,
                              weight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MenuDesign.accentDark,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: MenuDesign.card(shadow: true),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    MenuGhostButton(
                      label: 'Cancelar',
                      icon: Icons.close,
                      onPressed: widget.onBack,
                    ),
                    MenuPrimaryButton(
                      label: 'Guardar menú',
                      icon: Icons.check,
                      loading: _isLoading,
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
