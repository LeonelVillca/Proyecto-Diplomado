part of '../../../screens/movil/reservations/reservations_screen.dart';

class SelectorPestanasReserva extends StatelessWidget {
  const SelectorPestanasReserva({
    super.key,
    required this.cantidadProximas,
    required this.cantidadPasadas,
    required this.mostrarPasadas,
    required this.alCambiar,
  });

  final int cantidadProximas;
  final int cantidadPasadas;
  final bool mostrarPasadas;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        border: Border.all(color: ConsumerColors.line),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: PestanaReserva(
              label: 'Próximas',
              count: cantidadProximas,
              icon: LucideIcons.calendarClock,
              selected: !mostrarPasadas,
              onTap: () => alCambiar(false),
            ),
          ),
          Expanded(
            child: PestanaReserva(
              label: 'Pasadas',
              count: cantidadPasadas,
              icon: LucideIcons.history,
              selected: mostrarPasadas,
              onTap: () => alCambiar(true),
            ),
          ),
        ],
      ),
    );
  }
}
