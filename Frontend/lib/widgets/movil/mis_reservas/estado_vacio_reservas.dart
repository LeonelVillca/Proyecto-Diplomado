part of '../../../screens/movil/reservations/reservations_screen.dart';

class EstadoVacioReservas extends StatelessWidget {
  const EstadoVacioReservas({super.key, required this.mostrarPasadas});
  final bool mostrarPasadas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 24),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ConsumerColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: ConsumerColors.paperDeep,
              shape: BoxShape.circle,
            ),
            child: Icon(
              mostrarPasadas ? LucideIcons.history : LucideIcons.calendarDays,
              size: 30,
              color: ConsumerColors.wine,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            mostrarPasadas
                ? 'Aún no hay reservas pasadas'
                : 'Sin reservas próximas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            mostrarPasadas
                ? 'Aquí aparecerá el historial de tus visitas.'
                : 'Descubre un restaurante y reserva una mesa para tu próxima visita.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
