import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailInfoTab extends StatelessWidget {
  const DetailInfoTab({
    super.key,
    required this.restaurant,
    required this.schedule,
  });

  final Restaurant restaurant;
  final List<ScheduleDay> schedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant.tagline.trim().isNotEmpty) ...[
            _SectionTitle(title: 'Sobre el restaurante'),
            const SizedBox(height: 12),
            Text(
              restaurant.tagline,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
          ],
          if (restaurant.address != null ||
              (restaurant.lat != null && restaurant.lng != null)) ...[
            _SectionTitle(title: 'Ubicación'),
            const SizedBox(height: 16),
            _LocationCard(restaurant: restaurant),
            const SizedBox(height: 32),
          ],
          if (schedule.isNotEmpty) ...[
            _SectionTitle(title: 'Horarios de atención'),
            const SizedBox(height: 16),
            ...schedule.map((s) => _ScheduleRow(day: s)),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day});
  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day.dayLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${day.openTime} - ${day.closeTime}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ConsumerShadows.cardSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.address ?? restaurant.zone,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),
                if (restaurant.lat != null && restaurant.lng != null)
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${restaurant.lat},${restaurant.lng}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else if (context.mounted) {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showMaterialBanner(
                          MaterialBanner(
                            content: const Text('No se pudo abrir el mapa'),
                            backgroundColor: ConsumerColors.errorSoft,
                            actions: [
                              TextButton(
                                onPressed: messenger.hideCurrentMaterialBanner,
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('Cómo llegar'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
