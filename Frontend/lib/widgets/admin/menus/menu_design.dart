import 'package:flutter/material.dart';
import 'package:frontend/core/admin/theme_admin.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';

abstract final class MenuDesign {
  static const ink = AdminTheme.textDark;
  static const muted = AdminTheme.textMuted;
  static const accent = AdminTheme.primaryColor;
  static const accentDark = AdminTheme.primaryDark;
  static const accentSoft = AdminTheme.primaryLight;
  static const line = AdminTheme.border;
  static const cream = AdminTheme.background;
  static const olive = AdminTheme.accentColor;
  static const green = AdminTheme.success;

  static TextStyle title(
    double size, {
    Color color = ink,
    bool italic = false,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w500,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: -0.5,
    height: 1.16,
  );

  static TextStyle body(
    double size, {
    Color color = muted,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.4,
  );

  static BoxDecoration card({double radius = 22, bool shadow = false}) =>
      BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? AdminTheme.shadowSm : null,
      );
}

class MenuPageHeading extends StatelessWidget {
  const MenuPageHeading({
    super.key,
    required this.before,
    required this.emphasis,
    required this.subtitle,
    this.kicker,
  });
  final String before;
  final String emphasis;
  final String subtitle;
  final String? kicker;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (kicker != null) ...[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 24, height: 1.5, color: MenuDesign.accent),
            const SizedBox(width: 9),
            Text(
              kicker!.toUpperCase(),
              style: MenuDesign.body(
                11,
                color: MenuDesign.accent,
                weight: FontWeight.w700,
              ).copyWith(letterSpacing: 2),
            ),
          ],
        ),
        const SizedBox(height: 9),
      ],
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: before, style: MenuDesign.title(36)),
            TextSpan(
              text: emphasis,
              style: MenuDesign.title(
                36,
                color: MenuDesign.accent,
                italic: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      Text(subtitle, style: MenuDesign.body(14)),
    ],
  );
}

class MenuPrimaryButton extends StatelessWidget {
  const MenuPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: loading ? null : onPressed,
    icon: loading
        ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(icon, size: 17),
    label: Text(
      label,
      style: MenuDesign.body(
        13.5,
        color: Colors.white,
        weight: FontWeight.w700,
      ),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: MenuDesign.accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: MenuDesign.accent,
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
      shape: const StadiumBorder(),
      elevation: 3,
      shadowColor: MenuDesign.accent.withValues(alpha: .22),
    ),
  );
}

class MenuGhostButton extends StatelessWidget {
  const MenuGhostButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
    label: Text(
      label,
      style: MenuDesign.body(
        13,
        color: MenuDesign.ink,
        weight: FontWeight.w700,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: MenuDesign.ink,
      side: const BorderSide(color: MenuDesign.line),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: const StadiumBorder(),
    ),
  );
}

class MenuStatusBadge extends StatelessWidget {
  const MenuStatusBadge({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: visible ? AdminTheme.successSoft : const Color(0xFFF1EADD),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 13,
          color: visible ? MenuDesign.green : MenuDesign.muted,
        ),
        const SizedBox(width: 5),
        Text(
          visible ? 'Visible' : 'Oculto',
          style: MenuDesign.body(
            11,
            color: visible ? MenuDesign.green : MenuDesign.muted,
            weight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class MenuVisibilitySwitch extends StatelessWidget {
  const MenuVisibilitySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Visibilidad del menú',
    toggled: value,
    child: Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: MenuDesign.green,
      activeThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFE3DACA),
      inactiveThumbColor: Colors.white,
    ),
  );
}

class MenuDishImage extends StatelessWidget {
  const MenuDishImage({
    super.key,
    required this.plato,
    this.size = 40,
    this.radius = 12,
  });
  final PlatoAdminModel plato;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = plato.fotoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url.isEmpty
            ? const ColoredBox(
                color: MenuDesign.accentSoft,
                child: Icon(
                  Icons.restaurant_outlined,
                  color: MenuDesign.accent,
                  size: 21,
                ),
              )
            : Image.network(
                url.startsWith('/') ? '${ApiEndpoints.baseUrl}$url' : url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: MenuDesign.accentSoft,
                  child: Icon(
                    Icons.restaurant_outlined,
                    color: MenuDesign.accent,
                    size: 21,
                  ),
                ),
              ),
      ),
    );
  }
}

class MenuDashedBox extends StatelessWidget {
  const MenuDashedBox({
    super.key,
    required this.child,
    this.radius = 22,
    this.color = MenuDesign.line,
  });
  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _MenuDashPainter(radius: radius, color: color),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    ),
  );
}

class _MenuDashPainter extends CustomPainter {
  const _MenuDashPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 11) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MenuDashPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
