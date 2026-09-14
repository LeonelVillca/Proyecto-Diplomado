import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AdminNotificationType { success, error, info }

/// Notificación modal reutilizable para todas las pantallas del panel web.
///
/// Usa una capa oscura para separar el mensaje del contenido, una entrada
/// animada y cierre automático. Puede cerrarse manualmente tocando fuera o
/// usando el botón de cierre.
class AdminNotificationModal {
  const AdminNotificationModal._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    AdminNotificationType type = AdminNotificationType.success,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar notificación',
      barrierColor: Colors.black.withValues(alpha: 0.56),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _NotificationCard(
        message: message,
        title: title ?? _defaultTitle(type),
        type: type,
        duration: duration,
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> success(
    BuildContext context,
    String message, {
    String? title,
  }) => show(
        context,
        message: message,
        title: title,
        type: AdminNotificationType.success,
      );

  static Future<void> error(
    BuildContext context,
    String message, {
    String? title,
  }) => show(
        context,
        message: message,
        title: title,
        type: AdminNotificationType.error,
      );

  static Future<void> info(
    BuildContext context,
    String message, {
    String? title,
  }) => show(
        context,
        message: message,
        title: title,
        type: AdminNotificationType.info,
      );

  static String _defaultTitle(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.success:
        return '¡Listo!';
      case AdminNotificationType.error:
        return 'No se pudo completar';
      case AdminNotificationType.info:
        return 'Información';
    }
  }
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.message,
    required this.title,
    required this.type,
    required this.duration,
  });

  final String message;
  final String title;
  final AdminNotificationType type;
  final Duration duration;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _closeTimer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _NotificationScheme.fromType(widget.type);
    final width = MediaQuery.sizeOf(context).width;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 520 ? width - 40 : 460),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: scheme.color.withValues(alpha: 0.16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 36,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: scheme.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(scheme.icon, color: scheme.color, size: 30),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF241F1D),
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.message,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF756B66),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _close,
                        tooltip: 'Cerrar',
                        splashRadius: 20,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: const Color(0xFF9A918C),
                      ),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: widget.duration,
                  curve: Curves.linear,
                  builder: (_, value, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(height: 4, color: scheme.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationScheme {
  const _NotificationScheme(this.color, this.icon);

  final Color color;
  final IconData icon;

  factory _NotificationScheme.fromType(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.success:
        return const _NotificationScheme(Color(0xFF2EAF72), Icons.check_rounded);
      case AdminNotificationType.error:
        return const _NotificationScheme(Color(0xFFD95C5C), Icons.priority_high_rounded);
      case AdminNotificationType.info:
        return const _NotificationScheme(Color(0xFF4F82C2), Icons.info_outline_rounded);
    }
  }
}
