import 'package:flutter/material.dart';

import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant.dart';

/// Confirmation of the request submission. The reservation stays pending
/// until the restaurant approves it.
class ReservationSentScreen extends StatelessWidget {
  const ReservationSentScreen({
    super.key,
    required this.restaurant,
    required this.date,
    required this.time,
    required this.guests,
    required this.onMyReservations,
  });

  final Restaurant restaurant;
  final String date;
  final String time;
  final int guests;
  final VoidCallback onMyReservations;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ConsumerColors.paper,
    appBar: AppBar(title: const Text('Solicitud enviada')),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ConsumerColors.success, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: ConsumerColors.success,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Solicitud enviada!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu reserva en ${restaurant.name} quedó pendiente de confirmación.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ConsumerColors.card,
                    border: Border.all(color: ConsumerColors.line),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.address ?? restaurant.zone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: ConsumerColors.line),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Detail(
                              icon: Icons.event_outlined,
                              label: 'Fecha',
                              value: date,
                            ),
                          ),
                          Expanded(
                            child: _Detail(
                              icon: Icons.access_time_rounded,
                              label: 'Hora',
                              value: time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Detail(
                              icon: Icons.people_outline_rounded,
                              label: 'Personas',
                              value: guests.toString(),
                            ),
                          ),
                          const Expanded(
                            child: _Detail(
                              icon: Icons.timer_outlined,
                              label: 'Duración',
                              value: '2 horas',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ConsumerColors.card,
                    border: Border.all(color: ConsumerColors.line),
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
                          'Te avisaremos cuando el restaurante responda. Puedes revisar el estado en Mis reservas.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.4),
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
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: ConsumerColors.paper,
        border: Border(top: BorderSide(color: ConsumerColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onMyReservations,
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('Mis reservas'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: ConsumerColors.wine),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ConsumerColors.inkSoft,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ConsumerColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
