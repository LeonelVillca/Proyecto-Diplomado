import 'package:flutter/material.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'menu_design.dart';

class MenuCard extends StatefulWidget {
  const MenuCard({
    super.key,
    required this.menu,
    required this.onView,
    required this.onEdit,
    required this.onVisibilityChanged,
    required this.index,
  });
  final MenuAdminModel menu;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final ValueChanged<bool> onVisibilityChanged;
  final int index;

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final minPrice = menu.platos.isEmpty
        ? null
        : menu.platos.map((p) => p.precio).reduce((a, b) => a < b ? a : b);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 240 + widget.index.clamp(0, 6).toInt() * 55,
      ),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 12),
          child: child!,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: MenuDesign.card(shadow: hovered).copyWith(
            boxShadow: hovered
                ? const [
                    BoxShadow(
                      color: Color(0x1A26201A),
                      blurRadius: 34,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: MenuDesign.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        menu.tipo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MenuDesign.body(
                          11,
                          color: MenuDesign.accentDark,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  MenuStatusBadge(visible: menu.disponibilidad),
                  const Spacer(),
                  MenuVisibilitySwitch(
                    value: menu.disponibilidad,
                    onChanged: widget.onVisibilityChanged,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      menu.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MenuDesign.title(22),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text('#${menu.id}', style: MenuDesign.body(11)),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.restaurant_outlined,
                    size: 17,
                    color: MenuDesign.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${menu.platos.length} platillo${menu.platos.length == 1 ? '' : 's'}',
                    style: MenuDesign.body(12.5),
                  ),
                  const Spacer(),
                  if (minPrice != null)
                    Text(
                      'desde Bs ${minPrice.toStringAsFixed(2)}',
                      style: MenuDesign.title(16, color: MenuDesign.accentDark),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: 145,
                height: 44,
                child: Stack(
                  children: [
                    for (var i = 0; i < menu.platos.length && i < 3; i++)
                      Positioned(
                        left: i * 31.0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: MenuDishImage(plato: menu.platos[i]),
                        ),
                      ),
                    if (menu.platos.length > 3)
                      Positioned(
                        left: 93,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: MenuDesign.cream,
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${menu.platos.length - 3}',
                            style: MenuDesign.body(11, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              const Divider(color: MenuDesign.line, height: 24),
              Row(
                children: [
                  Expanded(
                    child: MenuGhostButton(
                      label: 'Ver',
                      icon: Icons.visibility_outlined,
                      onPressed: widget.onView,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MenuPrimaryButton(
                      label: 'Editar',
                      icon: Icons.edit_outlined,
                      onPressed: widget.onEdit,
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
}
