part of '../restaurant_detail_screen.dart';

extension _ResumenDetalleRestaurante on _RestaurantDetailScreenState {
  Widget _construirResumenRestaurante(
    BuildContext context,
    String? openStatus,
  ) {
    return Container(
      width: double.infinity,
      height: _RestaurantDetailScreenState._summaryHeight,
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: ConsumerColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.restaurant.reviewCount > 0)
                ResumenCalificacion(restaurant: widget.restaurant),
              _construirInsigniaCocina(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: ConsumerColors.wine,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.restaurant.address ?? widget.restaurant.zone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ConsumerColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (openStatus != null) ...[
            const SizedBox(height: 8),
            IndicadorAperturaRestaurante(label: openStatus),
          ],
        ],
      ),
    );
  }

  String? _obtenerEstadoApertura() {
    final schedules = widget.restaurant.schedule;
    if (schedules.isEmpty) return null;

    final now = DateTime.now();
    const days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    String normalize(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    int? toMinutes(String value) {
      final parts = value.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null ||
          minute == null ||
          hour > 24 ||
          minute > 59 ||
          (hour == 24 && minute != 0)) {
        return null;
      }
      return hour * 60 + minute;
    }

    final today = now.weekday - 1;
    final yesterday = (today + 6) % 7;
    final current = now.hour * 60 + now.minute;
    var hasValidSchedule = false;
    for (final item in schedules) {
      final day = days.indexOf(normalize(item.dayLabel));
      final opens = toMinutes(item.openTime);
      final closes = toMinutes(item.closeTime);
      if (day < 0 || opens == null || closes == null || opens == closes) {
        continue;
      }
      hasValidSchedule = true;

      if (day == today) {
        final isOpen = closes > opens
            ? current >= opens && current < closes
            : current >= opens;
        if (isOpen) {
          return 'Abierto ahora · hasta ${item.closeTime.substring(0, 5)}';
        }
      }
      if (day == yesterday && closes < opens && current < closes) {
        return 'Abierto ahora · hasta ${item.closeTime.substring(0, 5)}';
      }
    }
    return hasValidSchedule ? 'Cerrado ahora' : null;
  }

  Widget _construirInsigniaCocina() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ConsumerColors.wine.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.utensils,
            size: 13,
            color: ConsumerColors.wine,
          ),
          const SizedBox(width: 6),
          Text(
            widget.restaurant.cuisineLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: ConsumerColors.wine,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
