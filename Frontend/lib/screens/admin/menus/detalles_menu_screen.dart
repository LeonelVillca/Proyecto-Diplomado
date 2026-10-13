import 'package:flutter/material.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/widgets/admin/menus/menu_design.dart';
import 'package:frontend/widgets/admin/menus/menu_detail_widgets.dart';

class DetallesMenuScreen extends StatelessWidget {
  final MenuAdminModel menu;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final ValueChanged<bool> onVisibilityChanged;

  const DetallesMenuScreen({
    super.key,
    required this.menu,
    required this.onBack,
    required this.onEdit,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prices = menu.platos.map((p) => p.precio).toList();
    final min = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
    final max = prices.isEmpty ? null : prices.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 600 ? 0.0 : 32.0;
        final compact = constraints.maxWidth < 640;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuGhostButton(
                label: 'Volver a Gestión de menús',
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
              const SizedBox(height: 22),
              if (compact) ...[
                MenuPageHeading(
                  before: menu.nombre,
                  emphasis: '.',
                  kicker: menu.tipo,
                  subtitle: 'Platillos y datos de este menú.',
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    MenuStatusBadge(visible: menu.disponibilidad),
                    MenuVisibilitySwitch(
                      value: menu.disponibilidad,
                      onChanged: onVisibilityChanged,
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: MenuPageHeading(
                        before: menu.nombre,
                        emphasis: '.',
                        kicker: menu.tipo,
                        subtitle: 'Platillos y datos de este menú.',
                      ),
                    ),
                    const SizedBox(width: 16),
                    MenuStatusBadge(visible: menu.disponibilidad),
                    MenuVisibilitySwitch(
                      value: menu.disponibilidad,
                      onChanged: onVisibilityChanged,
                    ),
                  ],
                ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 17,
                ),
                decoration: MenuDesign.card(),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MenuSummaryItem(
                      icon: Icons.tag_outlined,
                      text: '#${menu.id}',
                    ),
                    MenuSummaryItem(
                      icon: Icons.restaurant_menu_outlined,
                      text: menu.tipo,
                    ),
                    MenuSummaryItem(
                      icon: Icons.restaurant_outlined,
                      text: '${menu.platos.length} platillos',
                    ),
                    if (min != null && max != null)
                      MenuSummaryItem(
                        icon: Icons.paid_outlined,
                        text:
                            'Bs ${min.toStringAsFixed(2)} – Bs ${max.toStringAsFixed(2)}',
                      ),
                    MenuStatusBadge(visible: menu.disponibilidad),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Platillos incluidos (${menu.platos.length})',
                style: MenuDesign.title(21),
              ),
              const SizedBox(height: 15),
              if (menu.platos.isEmpty)
                Text(
                  'Este menú no tiene platillos registrados.',
                  style: MenuDesign.body(13),
                )
              else
                ...menu.platos.map((p) => MenuDetailDishRow(plato: p)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: MenuDesign.card(),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? constraints.maxWidth - 36 : 420,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 19,
                            color: MenuDesign.olive,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              menu.disponibilidad
                                  ? 'Este menú está visible en tu perfil.'
                                  : 'Este menú está oculto para los comensales.',
                              style: MenuDesign.body(12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    MenuPrimaryButton(
                      label: 'Modificar este menú',
                      icon: Icons.edit_outlined,
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
