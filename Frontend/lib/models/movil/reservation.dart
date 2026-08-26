/// Reserva de mesa en un restaurante.
class Reservation {
  const Reservation({
    required this.id,
    required this.restaurant,
    required this.zone,
    required this.emoji,
    required this.date,
    required this.time,
    required this.guests,
    required this.upcoming,
  });

  final String id;
  final String restaurant;
  final String zone;
  final String emoji;
  final String date;
  final String time;
  final int guests;
  final bool upcoming;
}