import 'package:flutter/material.dart';

import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/models/admin/restaurante_admin_model.dart';
import 'package:frontend/widgets/admin/admin_ui.dart';

class AdminRestaurantDetailModal extends StatelessWidget {
  const AdminRestaurantDetailModal({super.key, required this.restaurant});

  final RestauranteAdminModel restaurant;

  static Future<void> show(BuildContext context, RestauranteAdminModel restaurant) => showDialog<void>(
        context: context,
        barrierColor: const Color(0x6B26201A),
        builder: (_) => AdminRestaurantDetailModal(restaurant: restaurant),
      );

  @override
  Widget build(BuildContext context) {
    final admin = restaurant.administrador;
    final adminName = admin == null ? null : '${admin['nombre'] ?? ''} ${admin['apellido'] ?? ''}'.trim();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final side = _RestaurantIdentity(restaurant: restaurant, compact: compact);
              final details = _RestaurantDetails(
                restaurant: restaurant,
                adminName: adminName?.isEmpty ?? true ? null : adminName,
                onClose: () => Navigator.pop(context),
              );
              return Container(
                decoration: const BoxDecoration(color: AdminTheme.surface),
                child: compact ? Column(mainAxisSize: MainAxisSize.min, children: [side, details]) : Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 225, child: side), Expanded(child: details)]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RestaurantIdentity extends StatelessWidget {
  const _RestaurantIdentity({required this.restaurant, required this.compact});
  final RestauranteAdminModel restaurant;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minHeight: compact ? 158 : 392),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AdminTheme.sidebar),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AdminStatusChip(status: restaurant.estado ? AdminStatus.active : AdminStatus.suspended, label: restaurant.estado ? 'Activo' : 'Suspendido'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AdminInitialAvatar(label: restaurant.nombre, size: compact ? 52 : 60),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(restaurant.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(restaurant.tipoComida ?? 'Sin categoría', style: const TextStyle(color: Color(0xD9FDF4EE), fontSize: 12, fontWeight: FontWeight.w600))])),
              ],
            ),
          ],
        ),
      );
}

class _RestaurantDetails extends StatelessWidget {
  const _RestaurantDetails({required this.restaurant, required this.adminName, required this.onClose});
  final RestauranteAdminModel restaurant;
  final String? adminName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: Text('Detalle del restaurante', style: AdminTheme.titleStyle.copyWith(fontSize: 22))), IconButton(tooltip: 'Cerrar', onPressed: onClose, icon: const Icon(Icons.close_rounded), color: AdminTheme.textMuted)]),
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _DetailTile(icon: Icons.restaurant_menu_rounded, label: 'Tipo de comida', value: restaurant.tipoComida, color: AdminTheme.primaryColor),
              _DetailTile(icon: Icons.phone_outlined, label: 'Teléfono', value: restaurant.telefono, color: AdminTheme.gold),
              _DetailTile(icon: Icons.mail_outline_rounded, label: 'Correo', value: restaurant.correo, color: AdminTheme.accentColor, wide: true),
              _DetailTile(icon: Icons.inbox_outlined, label: 'Solicitud', value: restaurant.solicitudEstado, color: const Color(0xFF4B4B8F)),
              _DetailTile(icon: Icons.manage_accounts_outlined, label: 'Administrador', value: adminName, color: AdminTheme.textMuted),
            ]),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AdminTheme.background, border: Border.all(color: AdminTheme.border), borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: AdminTheme.gold), SizedBox(width: 8), Expanded(child: Text('Los datos mostrados corresponden a la cuenta real del restaurante.', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted)))])),
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: onClose, child: const Text('Cerrar'))),
          ],
        ),
      );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.icon, required this.label, required this.value, required this.color, this.wide = false});
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final bool wide;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: wide ? 365 : 175,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AdminTheme.background, border: Border.all(color: AdminTheme.border), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 17, color: color)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, letterSpacing: .7, fontWeight: FontWeight.w700, color: AdminTheme.textMuted)), const SizedBox(height: 3), Text(value?.isNotEmpty == true ? value! : 'No registrado', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: value?.isNotEmpty == true ? AdminTheme.textDark : AdminTheme.textMuted))]))]),
        ),
      );
}
