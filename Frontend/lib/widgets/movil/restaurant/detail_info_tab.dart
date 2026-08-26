import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

class DetailInfoTab extends StatelessWidget {
  const DetailInfoTab({super.key, required this.restaurant, required this.schedule});

  final Restaurant restaurant;
  final List<ScheduleDay> schedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Sobre el restaurante'),
          const SizedBox(height: 12),
          Text(
            restaurant.tagline.isNotEmpty ? restaurant.tagline : 'No hay una descripción disponible todavía. ¡Sé el primero en descubrir este lugar y contarnos tu experiencia!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 32),
          _SectionTitle(title: 'Ubicación'),
          const SizedBox(height: 16),
          _LocationCard(restaurant: restaurant),

          const SizedBox(height: 32),
          _SectionTitle(title: 'Contacto'),
          const SizedBox(height: 16),
          _ContactCard(restaurant: restaurant),

          const SizedBox(height: 32),
          _SectionTitle(title: 'Horarios de atención'),
          const SizedBox(height: 16),
          if (schedule.isEmpty)
            Text('Escríbele al restaurante antes de ir para confirmar que esté abierto.', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...schedule.map((s) => _ScheduleRow(day: s)),
            
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: restaurant.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Administración', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text('Atención al cliente', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          _ContactButton(icon: Icons.phone_rounded),
          const SizedBox(width: 8),
          _ContactButton(icon: Icons.chat_bubble_outline_rounded),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.paperDeep,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.wine, size: 20),
    );
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
          Text(day.dayLabel, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text('${day.openTime} - ${day.closeTime}', style: Theme.of(context).textTheme.bodyMedium),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Mapa ilustrado
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.paperDeep),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ilustracion estilizada (usaremos el logo actual como placeholder de mapa, pero con blend mode)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset('assets/tarija_food.png', fit: BoxFit.cover, color: AppColors.terracotta, colorBlendMode: BlendMode.color),
                  ),
                ),
                // Pin
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.cardStrong,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.zone, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Tarija, Bolivia', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paperDeep,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Cómo llegar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.wine, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
