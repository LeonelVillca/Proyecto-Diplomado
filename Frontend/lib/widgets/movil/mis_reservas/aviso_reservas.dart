part of '../../../screens/movil/reservations/reservations_screen.dart';

class AvisoReservas extends StatelessWidget {
  const AvisoReservas({super.key, required this.hayPendientes});
  final bool hayPendientes;

  @override
  Widget build(BuildContext context) {
    final hasPending = hayPendientes;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(
          color: ConsumerColors.line,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: ConsumerColors.wine,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasPending
                  ? 'Tu solicitud sigue pendiente. Aquí verás cuando el restaurante la confirme.'
                  : 'Puedes consultar aquí el estado y los datos de tus reservas.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
