import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/movil/reservations/reservation_schedule.dart';

void main() {
  test('solo muestra días de atención y horas que admiten una hora', () {
    final days = reservationDays(
      now: DateTime(2026, 9, 21, 10),
      horizonDays: 7,
      weekly: const [
        WeeklyHours(weekday: 0, start: '12:00:00', end: '16:00:00'),
        WeeklyHours(weekday: 5, start: '12:00:00', end: '16:00:00'),
        WeeklyHours(weekday: 6, start: '12:00:00', end: '16:00:00'),
      ],
      exceptions: const [],
    );

    expect(days.map((day) => reservationDateKey(day.date)).toList(), [
      '2026-09-21',
      '2026-09-26',
      '2026-09-27',
    ]);
    expect(days.first.slots, [
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
    ]);
  });

  test('las excepciones cierran o abren un día y reemplazan su horario', () {
    final days = reservationDays(
      now: DateTime(2026, 9, 21, 10),
      horizonDays: 7,
      weekly: const [
        WeeklyHours(weekday: 0, start: '12:00', end: '16:00'),
        WeeklyHours(weekday: 5, start: '12:00', end: '16:00'),
      ],
      exceptions: const [
        HoursException(
          date: '2026-09-21',
          closed: false,
          start: '19:00',
          end: '22:00',
        ),
        HoursException(
          date: '2026-09-22',
          closed: false,
          start: '12:00',
          end: '14:00',
        ),
        HoursException(date: '2026-09-26', closed: true),
      ],
    );

    expect(days.map((day) => reservationDateKey(day.date)).toList(), [
      '2026-09-21',
      '2026-09-22',
    ]);
    expect(days.first.slots, [
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
    ]);
    expect(days.last.slots, ['12:00', '12:30', '13:00']);
  });

  test('no ofrece horas ya pasadas en el día actual', () {
    final days = reservationDays(
      now: DateTime(2026, 9, 21, 13, 15),
      horizonDays: 1,
      weekly: const [WeeklyHours(weekday: 0, start: '12:00', end: '16:00')],
      exceptions: const [],
    );
    expect(days.single.slots, [
      '13:30',
      '14:00',
      '14:30',
      '15:00',
    ]);
  });
}
