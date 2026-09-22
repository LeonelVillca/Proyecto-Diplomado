import 'package:flutter/material.dart';

import 'package:frontend/core/admin/theme_admin.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.kicker,
    required this.titleBefore,
    required this.titleEmphasis,
    required this.description,
    this.actions,
  });

  final String kicker;
  final String titleBefore;
  final String titleEmphasis;
  final String description;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 24, height: 2, color: AdminTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    color: AdminTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.56,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: AdminTheme.titleStyle,
                children: [
                  TextSpan(text: titleBefore),
                  TextSpan(
                    text: titleEmphasis,
                    style: AdminTheme.titleStyle.copyWith(
                      color: AdminTheme.primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Text(description, style: AdminTheme.bodyStyle),
            ),
          ],
        );

        if (actions == null || actions!.isEmpty) return heading;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(width: compact ? constraints.maxWidth : null, child: heading),
            Wrap(spacing: 10, runSpacing: 10, children: actions!),
          ],
        );
      },
    );
  }
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({super.key, required this.child, this.padding, this.radius});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          border: Border.all(color: AdminTheme.border),
          borderRadius: radius ?? AdminTheme.cardRadius,
          boxShadow: AdminTheme.shadowSm,
        ),
        child: child,
      );
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.onChanged,
    required this.hintText,
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
        ),
      );
}

class AdminInitialAvatar extends StatelessWidget {
  const AdminInitialAvatar({super.key, required this.label, this.round = false, this.size = 42});

  final String label;
  final bool round;
  final double size;

  static const _colors = [
    AdminTheme.primaryColor,
    AdminTheme.accentColor,
    AdminTheme.gold,
    Color(0xFF4B4B8F),
    Color(0xFF2E7D6B),
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim();
    final value = normalized.runes.fold<int>(0, (sum, rune) => sum + rune);
    final initials = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(round ? 2 : 1)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colors[value % _colors.length],
        borderRadius: round ? BorderRadius.circular(size / 2) : BorderRadius.circular(13),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontFamily: round ? 'InstrumentSans' : 'Fraunces',
          fontWeight: FontWeight.w700,
          fontSize: round ? size * .34 : size * .43,
        ),
      ),
    );
  }
}

enum AdminStatus { active, pending, suspended, inactive }

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status, required this.label});

  final AdminStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      AdminStatus.active => (AdminTheme.successSoft, AdminTheme.success),
      AdminStatus.pending => (AdminTheme.warningSoft, AdminTheme.warning),
      AdminStatus.suspended => (AdminTheme.errorSoft, AdminTheme.error),
      AdminStatus.inactive => (AdminTheme.surfaceMuted, AdminTheme.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: AdminTheme.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
