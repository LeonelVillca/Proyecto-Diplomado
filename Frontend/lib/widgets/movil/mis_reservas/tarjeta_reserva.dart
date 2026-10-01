part of '../../../screens/movil/reservations/reservations_screen.dart';

class TarjetaReserva extends StatelessWidget {
  const TarjetaReserva({
    super.key,
    required this.reserva,
    required this.puedeCancelar,
    required this.estaCancelando,
    required this.onCancelar,
  });

  final ReservaAdminModel reserva;
  final bool puedeCancelar;
  final bool estaCancelando;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final reserva = this.reserva;
    Widget placeholderRestaurantImage() => const ColoredBox(
      color: ConsumerColors.paperDeep,
      child: Icon(LucideIcons.utensils, color: ConsumerColors.wine),
    );

    Widget restaurantImage() {
      final logo = reserva.restauranteLogo;
      final cover = reserva.restauranteFoto;
      final imageUrl = logo ?? cover;
      if (imageUrl == null || imageUrl.isEmpty) {
        return placeholderRestaurantImage();
      }
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (cover != null && cover.isNotEmpty && cover != imageUrl) {
            return Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholderRestaurantImage(),
            );
          }
          return placeholderRestaurantImage();
        },
      );
    }

    final date = reserva.fechaHora;
    final today = DateTime.now();
    final sameDay =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final tomorrow =
        date.difference(DateTime(today.year, today.month, today.day)).inDays ==
        1;
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final dateLabel = sameDay
        ? 'Hoy'
        : tomorrow
        ? 'Mañana'
        : days[date.weekday - 1] +
              ' ' +
              date.day.toString() +
              ' ' +
              months[date.month - 1];
    final timeLabel =
        date.hour.toString().padLeft(2, '0') +
        ':' +
        date.minute.toString().padLeft(2, '0');
    final status = reserva.estado.toLowerCase();
    final statusColor = status == 'confirmada'
        ? ConsumerColors.success
        : status == 'pendiente'
        ? ConsumerColors.warning
        : status == 'cancelada' || status == 'rechazada'
        ? ConsumerColors.error
        : ConsumerColors.inkSoft;
    final statusBackground = status == 'confirmada'
        ? ConsumerColors.successSoft
        : status == 'pendiente'
        ? ConsumerColors.warningSoft
        : status == 'cancelada' || status == 'rechazada'
        ? ConsumerColors.errorSoft
        : ConsumerColors.paperDeep;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(color: ConsumerColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: restaurantImage(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            reserva.restauranteNombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'confirmada')
                                Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: statusColor,
                                ),
                              if (status == 'confirmada')
                                const SizedBox(width: 3),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateLabel + ' · ' + timeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ConsumerColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.users,
                          size: 14,
                          color: ConsumerColors.inkSoft,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          reserva.cantidadPersonas.toString() + ' personas',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((reserva.numeroMesa ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ConsumerColors.paperDeep,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Mesa ' + reserva.numeroMesa!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ConsumerColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if ((status == 'pendiente' || status == 'confirmada') &&
              puedeCancelar) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancelar,
                icon: const Icon(LucideIcons.x, size: 15),
                label: Text(estaCancelando ? 'Cancelando...' : 'Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ConsumerColors.error,
                  side: const BorderSide(color: Color(0xFFF0CFC6)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
