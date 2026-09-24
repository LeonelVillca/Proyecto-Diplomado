class WeeklyHours {
  const WeeklyHours({
    required this.weekday,
    required this.start,
    required this.end,
  });

  /// 0 = lunes, 6 = domingo; igual que el backend.
  final int weekday;
  final String start;
  final String end;
}

class HoursException {
  const HoursException({
    required this.date,
    required this.closed,
    this.start,
    this.end,
  });

  final String date;
  final bool closed;
  final String? start;
  final String? end;
}

class ReservationDay {
  const ReservationDay(this.date, this.slots);

  final DateTime date;
  final List<String> slots;
}

String reservationDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

int? _seconds(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = parts.length > 2 ? int.tryParse(parts[2]) : 0;
  if (hour == null ||
      minute == null ||
      second == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59 ||
      second < 0 ||
      second > 59) {
    return null;
  }
  return hour * 3600 + minute * 60 + second;
}

String _timeLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

List<ReservationDay> reservationDays({
  required DateTime now,
  required List<WeeklyHours> weekly,
  required List<HoursException> exceptions,
  int horizonDays = 14,
  int durationMinutes = 120,
}) {
  final special = {
    for (final exception in exceptions) exception.date: exception,
  };
  final firstDay = DateTime(now.year, now.month, now.day);
  final days = <ReservationDay>[];

  for (var offset = 0; offset < horizonDays; offset++) {
    final date = firstDay.add(Duration(days: offset));
    final exception = special[reservationDateKey(date)];
    if (exception?.closed == true) continue;

    final windows = exception != null
        ? <({String start, String end})>[
            if (exception.start != null && exception.end != null)
              (start: exception.start!, end: exception.end!),
          ]
        : [
            for (final hours in weekly)
              if (hours.weekday == date.weekday - 1)
                (start: hours.start, end: hours.end),
          ];

    final slots = <String>{};
    for (final window in windows) {
      final start = _seconds(window.start);
      final end = _seconds(window.end);
      if (start == null || end == null) continue;
      final firstSlot = ((start + 1799) ~/ 1800) * 30;
      for (
        var minute = firstSlot;
        minute * 60 + durationMinutes * 60 <= end;
        minute += 30
      ) {
        final startTime = date.add(Duration(minutes: minute));
        if (startTime.isAfter(now)) slots.add(_timeLabel(minute));
      }
    }
    if (slots.isNotEmpty) {
      days.add(ReservationDay(date, slots.toList()..sort()));
    }
  }

  return days;
}
