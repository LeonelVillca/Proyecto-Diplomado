part of '../../../screens/movil/home/home_screen.dart';

class EncabezadoInicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName ?? '';
    final firstName = displayName.trim().isEmpty
        ? 'bienvenido'
        : displayName.trim().split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Avatar de la sesión
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ConsumerColors.sage,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              firstName[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Saludo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 12,
                    color: _C.textSoft,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Hola, '),
                      TextSpan(
                        text: '$firstName.',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: _C.accent,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: _C.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ValueListenableBuilder<int>(
              valueListenable: NotificationsService.unread,
              builder: (context, count, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notificaciones',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _C.surface,
                      foregroundColor: _C.textMid,
                      side: const BorderSide(color: ConsumerColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(LucideIcons.bell, size: 20),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: _C.accent,
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Barra de búsqueda
// ──────────────────────────────────────────────────────────────────────
