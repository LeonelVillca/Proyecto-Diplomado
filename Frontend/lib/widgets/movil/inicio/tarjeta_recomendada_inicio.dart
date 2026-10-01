part of '../../../screens/movil/home/home_screen.dart';

class TarjetaRecomendadaInicio extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const TarjetaRecomendadaInicio({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOpenNow = _restauranteAbiertoAhora(restaurant);
    return SizedBox(
      width: 300,
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: ConsumerColors.line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 112,
                    height: 148,
                    child: restaurant.photoUrl == null
                        ? const ColoredBox(
                            color: ConsumerColors.paperDeep,
                            child: Icon(LucideIcons.utensils, color: _C.accent),
                          )
                        : Image.network(
                            restaurant.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: ConsumerColors.paperDeep,
                              child: Icon(
                                LucideIcons.utensils,
                                color: _C.accent,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _C.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (restaurant.reviewCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: ConsumerColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.text,
                              ),
                            ),
                            Text(
                              ' (${restaurant.reviewCount} ${restaurant.reviewCount == 1 ? 'reseña' : 'reseñas'})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _C.textSoft,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Sin reseñas',
                          style: TextStyle(fontSize: 11, color: _C.textSoft),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.cuisineLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textSoft,
                        ),
                      ),
                      if (isOpenNow != null) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOpenNow
                                ? ConsumerColors.successSoft
                                : ConsumerColors.paperDeep,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock3,
                                size: 12,
                                color: isOpenNow
                                    ? ConsumerColors.success
                                    : _C.textMid,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOpenNow ? 'Abierto ahora' : 'Cerrado ahora',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOpenNow
                                      ? ConsumerColors.success
                                      : _C.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Ver restaurante',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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

bool? _restauranteAbiertoAhora(Restaurant restaurant, [DateTime? currentTime]) {
  if (restaurant.schedule.isEmpty) return null;

  final now = currentTime ?? DateTime.now();
  final dayNames = const [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];
  String normalizarTexto(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  int? parseMinutes(String value) {
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
  final minuteNow = now.hour * 60 + now.minute;
  var hasValidSchedule = false;
  for (final schedule in restaurant.schedule) {
    final day = dayNames.indexOf(normalizarTexto(schedule.dayLabel));
    final opens = parseMinutes(schedule.openTime);
    final closes = parseMinutes(schedule.closeTime);
    if (day < 0 || opens == null || closes == null || opens == closes) continue;
    hasValidSchedule = true;

    if (day == today) {
      if (closes > opens && minuteNow >= opens && minuteNow < closes) {
        return true;
      }
      if (closes < opens && minuteNow >= opens) return true;
    }
    if (day == yesterday && closes < opens && minuteNow < closes) {
      return true;
    }
  }
  return hasValidSchedule ? false : null;
}
// El _ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart
// El ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart

// ──────────────────────────────────────────────────────────────────────
// Sin resultados
// ──────────────────────────────────────────────────────────────────────

bool? _restauranteAbiertoAhora(Restaurant restaurant, [DateTime? currentTime]) {
  if (restaurant.schedule.isEmpty) return null;

  final now = currentTime ?? DateTime.now();
  final dayNames = const [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];
  String normalizarTexto(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  int? parseMinutes(String value) {
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
  final minuteNow = now.hour * 60 + now.minute;
  var hasValidSchedule = false;
  for (final schedule in restaurant.schedule) {
    final day = dayNames.indexOf(normalizarTexto(schedule.dayLabel));
    final opens = parseMinutes(schedule.openTime);
    final closes = parseMinutes(schedule.closeTime);
    if (day < 0 || opens == null || closes == null || opens == closes) continue;
    hasValidSchedule = true;

    if (day == today) {
      if (closes > opens && minuteNow >= opens && minuteNow < closes) {
        return true;
      }
      if (closes < opens && minuteNow >= opens) return true;
    }
    if (day == yesterday && closes < opens && minuteNow < closes) {
      return true;
    }
  }
  return hasValidSchedule ? false : null;
}
// El _ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart
// El ExploreCard fue extraído a lib/widgets/movil/restaurant/explore_card.dart

// ──────────────────────────────────────────────────────────────────────
// Sin resultados
// ──────────────────────────────────────────────────────────────────────
