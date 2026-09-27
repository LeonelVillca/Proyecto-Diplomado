import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/models/movil/restaurant.dart';

/// Confirma la solicitud con los datos reales del formulario. El estado sigue
/// pendiente hasta que el restaurante la confirme.
class ReservationSentDialog extends StatelessWidget {
  const ReservationSentDialog({
    super.key,
    required this.restaurant,
    required this.date,
    required this.time,
    required this.guests,
    required this.onClose,
  });

  final Restaurant restaurant;
  final String date;
  final String time;
  final int guests;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: ConsumerColors.paper,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 370),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 800),
              builder: (context, progress, _) => SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        color: ConsumerColors.success,
                        backgroundColor: ConsumerColors.successSoft,
                      ),
                    ),
                    if (progress > .85)
                      const Icon(
                        LucideIcons.check,
                        size: 42,
                        color: ConsumerColors.success,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solicitud enviada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: ConsumerColors.ink,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Tu reserva está pendiente de confirmación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ConsumerColors.inkSoft),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ConsumerColors.card,
                border: Border.all(color: ConsumerColors.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: ConsumerColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: ConsumerColors.line),
                  const SizedBox(height: 8),
                  _Detail(
                    icon: LucideIcons.calendar,
                    label: 'Fecha',
                    value: date,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Detail(
                          icon: LucideIcons.clock,
                          label: 'Hora',
                          value: time,
                        ),
                      ),
                      Expanded(
                        child: _Detail(
                          icon: LucideIcons.users,
                          label: 'Personas',
                          value: guests.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onClose,
                child: const Text('Entendido'),
              ),
            ),
          ],
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: ConsumerColors.inkSoft,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ConsumerColors.ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
