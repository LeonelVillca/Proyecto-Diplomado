import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'menu_design.dart';

class MenuFormSection extends StatelessWidget {
  const MenuFormSection({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.olive = false,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final bool olive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: MenuDesign.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: olive ? const Color(0xFFE7EDDF) : MenuDesign.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: olive ? MenuDesign.olive : MenuDesign.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MenuDesign.title(19)),
                  Text(description, style: MenuDesign.body(12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}

class MenuFormField extends StatelessWidget {
  const MenuFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isNumber = false,
    this.prefix,
    this.maxLines = 1,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isNumber;
  final String? prefix;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: MenuDesign.body(
          12,
          color: MenuDesign.ink,
          weight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: MenuDesign.body(13.5, color: MenuDesign.ink),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          prefixStyle: MenuDesign.body(
            13.5,
            color: MenuDesign.accentDark,
            weight: FontWeight.w700,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MenuDesign.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MenuDesign.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MenuDesign.accent, width: 1.5),
          ),
        ),
        validator: (v) => v!.trim().isEmpty
            ? 'Requerido'
            : (isNumber && double.tryParse(v) == null ? 'Inválido' : null),
      ),
    ],
  );
}

class MenuDishEditor extends StatelessWidget {
  const MenuDishEditor({
    super.key,
    required this.plato,
    required this.onPhoto,
    required this.onDelete,
  });
  final Map<String, dynamic> plato;
  final VoidCallback onPhoto;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 650;
      final photo = InkWell(
        onTap: onPhoto,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: MenuDesign.accentSoft,
            border: Border.all(
              color: MenuDesign.line,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: plato['bytes'] != null
              ? Image.memory(plato['bytes'] as Uint8List, fit: BoxFit.cover)
              : plato['fotoUrl'] != null
              ? Image.network(
                  plato['fotoUrl'].toString().startsWith('/')
                      ? '${ApiEndpoints.baseUrl}${plato['fotoUrl']}'
                      : plato['fotoUrl'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _placeholder(),
                )
              : _placeholder(),
        ),
      );
      final name = MenuFormField(
        label: 'Nombre del platillo',
        hint: 'Ej: Chicharrón de chancho',
        controller: plato['nombreCtrl'],
      );
      final description = MenuFormField(
        label: 'Descripción corta',
        hint: 'Describe el platillo',
        controller: plato['descCtrl'],
      );
      final price = MenuFormField(
        label: 'Precio',
        hint: '0.00',
        controller: plato['precioCtrl'],
        isNumber: true,
        prefix: 'Bs  ',
      );
      final delete = IconButton(
        onPressed: onDelete,
        tooltip: 'Quitar platillo',
        icon: const Icon(Icons.delete_outline, size: 21),
        style: IconButton.styleFrom(
          foregroundColor: MenuDesign.muted,
          backgroundColor: Colors.white,
          side: const BorderSide(color: MenuDesign.line),
          minimumSize: const Size(46, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MenuDesign.cream,
          border: Border.all(color: MenuDesign.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [photo, const Spacer(), delete]),
                  const SizedBox(height: 14),
                  name,
                  const SizedBox(height: 12),
                  description,
                  const SizedBox(height: 12),
                  price,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photo,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [name, const SizedBox(height: 12), description],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 118, child: price),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 23),
                    child: delete,
                  ),
                ],
              ),
      );
    },
  );

  Widget _placeholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.add_photo_alternate_outlined,
        color: MenuDesign.accent,
        size: 26,
      ),
      const SizedBox(height: 3),
      Text(
        'Subir foto',
        style: MenuDesign.body(
          11,
          color: MenuDesign.accentDark,
          weight: FontWeight.w700,
        ),
      ),
    ],
  );
}
