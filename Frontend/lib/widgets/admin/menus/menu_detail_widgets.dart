import 'package:flutter/material.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'menu_design.dart';

class MenuDetailDishRow extends StatefulWidget {
  const MenuDetailDishRow({super.key, required this.plato});
  final PlatoAdminModel plato;
  @override
  State<MenuDetailDishRow> createState() => _MenuDetailDishRowState();
}

class _MenuDetailDishRowState extends State<MenuDetailDishRow> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: MenuDesign.card(radius: 20, shadow: hovered),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = MenuDishImage(
            plato: widget.plato,
            size: 96,
            radius: 16,
          );
          final name = Text(
            widget.plato.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: MenuDesign.body(
              15,
              color: MenuDesign.ink,
              weight: FontWeight.w700,
            ),
          );
          final description = Text(
            widget.plato.descripcion.isNotEmpty
                ? widget.plato.descripcion
                : 'Sin descripción.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: MenuDesign.body(12.5),
          );
          final price = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PORCIÓN',
                style: MenuDesign.body(
                  10,
                  color: MenuDesign.muted,
                  weight: FontWeight.w700,
                ).copyWith(letterSpacing: 1.2),
              ),
              Text(
                'Bs ${widget.plato.precio.toStringAsFixed(2)}',
                style: MenuDesign.title(21, color: MenuDesign.accentDark),
              ),
            ],
          );
          return constraints.maxWidth < 500
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          const SizedBox(height: 4),
                          description,
                          const SizedBox(height: 8),
                          price,
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    image,
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          const SizedBox(height: 5),
                          description,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    price,
                  ],
                );
        },
      ),
    ),
  );
}

class MenuSummaryItem extends StatelessWidget {
  const MenuSummaryItem({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: MenuDesign.accent),
      const SizedBox(width: 7),
      Text(
        text,
        style: MenuDesign.body(
          13,
          color: MenuDesign.ink,
          weight: FontWeight.w600,
        ),
      ),
    ],
  );
}
