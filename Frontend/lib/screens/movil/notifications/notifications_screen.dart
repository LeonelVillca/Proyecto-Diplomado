import 'package:flutter/material.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/screens/movil/shell/main_shell.dart';
import 'package:frontend/services/movil/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ReservationNotice> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    NotificationsService.changed.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    NotificationsService.changed.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationsService.fetch();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los avisos.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(ReservationNotice notice) async {
    if (!notice.isRead) {
      try {
        await NotificationsService.markRead(notice.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo marcar el aviso como leído.'),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    MainShell.openReservations();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ConsumerColors.paper,
    appBar: AppBar(
      title: const Text('Notificaciones'),
      backgroundColor: ConsumerColors.paper,
      foregroundColor: ConsumerColors.ink,
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(child: Text(_error!)),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            )
          : _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Icon(
                  Icons.notifications_none_rounded,
                  size: 44,
                  color: ConsumerColors.inkSoft,
                ),
                SizedBox(height: 12),
                Center(child: Text('Aún no tienes avisos de reservas.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notice = _items[index];
                final approved = notice.type == 'reserva_confirmada';
                return Material(
                  color: ConsumerColors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(notice),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            approved
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            color: approved
                                ? ConsumerColors.success
                                : ConsumerColors.wine,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.title,
                                  style: TextStyle(
                                    fontWeight: notice.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: ConsumerColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notice.message,
                                  style: const TextStyle(
                                    color: ConsumerColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Ver mis reservas',
                                  style: const TextStyle(
                                    color: ConsumerColors.wine,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notice.isRead)
                            const CircleAvatar(
                              radius: 4,
                              backgroundColor: ConsumerColors.wine,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}
