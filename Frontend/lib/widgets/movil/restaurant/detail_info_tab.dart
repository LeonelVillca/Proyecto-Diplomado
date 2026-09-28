import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';
import 'package:frontend/screens/movil/profile/user_support_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    final todaySchedule = schedule
        .where((day) => _normalize(day.dayLabel) == _todayLabel())
        .toList();
    final isOpen = todaySchedule.any(_isCurrentlyOpen);
    final hours = todaySchedule
        .map(
          (day) => '${_shortTime(day.openTime)} – ${_shortTime(day.closeTime)}',
        )
        .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (restaurant.tagline.trim().isNotEmpty)
          _InfoCard(
            icon: Icons.storefront_outlined,
            iconColor: ConsumerColors.wine,
            title: 'Sobre el restaurante',
            child: Text(
              restaurant.tagline,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        if (restaurant.address != null ||
            (restaurant.lat != null && restaurant.lng != null)) ...[
          const SizedBox(height: 14),
          _LocationCard(restaurant: restaurant),
        ],
        const SizedBox(height: 14),
        _ContactCard(restaurant: restaurant),
        if (schedule.isNotEmpty) ...[
          const SizedBox(height: 14),
          _InfoCard(
            icon: Icons.access_time_rounded,
            iconColor: ConsumerColors.wine,
            title: isOpen ? 'Hoy abierto' : 'Hoy cerrado',
            child: Text(
              hours.isEmpty ? 'Horario no disponible' : hours,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConsumerColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = restaurant.lat != null && restaurant.lng != null;
    return Container(
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConsumerColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const _IconTile(
                  icon: Icons.location_on_outlined,
                  color: ConsumerColors.sage,
                ),
                const SizedBox(width: 10),
                Text(
                  'Ubicación',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
              ],
            ),
          ),
          if (hasCoordinates)
            SizedBox(
              height: 145,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(restaurant.lat!, restaurant.lng!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('restaurant-location'),
                    position: LatLng(restaurant.lat!, restaurant.lng!),
                    infoWindow: InfoWindow(title: restaurant.name),
                  ),
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: ConsumerColors.wine,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        restaurant.address ?? restaurant.zone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ConsumerColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openDirections(),
                    icon: const Icon(Icons.near_me_outlined, size: 17),
                    label: const Text('Cómo llegar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ConsumerColors.wineSoft,
                      foregroundColor: ConsumerColors.wineDark,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections() async {
    final destination = restaurant.lat != null && restaurant.lng != null
        ? '${restaurant.lat},${restaurant.lng}'
        : restaurant.address ?? restaurant.zone;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final phone = restaurant.phone?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ConsumerColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ConsumerColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.call_outlined,
                color: ConsumerColors.gold,
              ),
              const SizedBox(width: 10),
              Text(
                'Contacto',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ContactRow(
              icon: Icons.call_outlined,
              title: 'Administración',
              subtitle: phone,
              action: 'Llamar',
              onTap: () => _launch(Uri(scheme: 'tel', path: phone)),
            ),
            const Divider(height: 18, color: ConsumerColors.hairline),
            _ContactRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'WhatsApp',
              subtitle: 'Respuesta en el día',
              action: 'Escribir',
              onTap: () {
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                _launch(Uri.https('wa.me', '/$digits'));
              },
            ),
            const Divider(height: 18, color: ConsumerColors.hairline),
          ] else
            const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.headset_mic_outlined,
            title: 'Atención Mesa Chapaca',
            subtitle: 'Soporte al comensal · Lun a Sáb',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UserSupportScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: ConsumerColors.wine),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (action != null)
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(72, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: ConsumerColors.line),
              ),
              child: Text(action!, style: const TextStyle(fontSize: 12)),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: ConsumerColors.inkSoft,
            ),
        ],
      ),
    );
  }
}

String _todayLabel() => const [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
][DateTime.now().weekday - 1];

String _normalize(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;

bool _isCurrentlyOpen(ScheduleDay day) {
  final start = _minutes(day.openTime);
  final end = _minutes(day.closeTime);
  if (start == null || end == null) return false;
  final now = DateTime.now().hour * 60 + DateTime.now().minute;
  return end > start ? now >= start && now < end : now >= start || now < end;
}

int? _minutes(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  if (hours == null || minutes == null) return null;
  return hours * 60 + minutes;
}
