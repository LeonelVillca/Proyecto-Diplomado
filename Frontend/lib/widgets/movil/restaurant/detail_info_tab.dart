import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';
import 'package:frontend/models/movil/restaurant_detail.dart';

/// Tab de informacion: descripcion, contacto, horarios.
class DetailInfoTab extends StatelessWidget {
  const DetailInfoTab({super.key, required this.restaurant, required this.schedule});

  final Restaurant restaurant;
  final List<ScheduleDay> schedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Sobre el restaurante'),
          const SizedBox(height: 8),
          Text(
            restaurant.tagline + ' Un espacio donde la tradicion tarijena se fusiona con la buena mesa, el vino del valle y la hospitalidad chapaca.',
            style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.secondaryText, height: 1.6),
          ),

          const SizedBox(height: 20),
          _SectionTitle(title: 'Ubicacion'),
          const SizedBox(height: 10),
          _LocationCard(restaurant: restaurant),

          const SizedBox(height: 20),
          _SectionTitle(title: 'Contacto'),
          const SizedBox(height: 10),
          _ContactCard(restaurant: restaurant),

          const SizedBox(height: 20),
          _SectionTitle(title: 'Horarios de atencion'),
          const SizedBox(height: 10),
          ...schedule.map((s) => _ScheduleRow(day: s)),
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
    return Text(title,
        style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink));
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.restaurant});
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: restaurant.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Propietario del local',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(restaurant.zone,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondaryText)),
              ],
            ),
          ),
          _ContactButton(icon: Icons.phone_rounded),
          const SizedBox(width: 8),
          _ContactButton(icon: Icons.chat_bubble_rounded),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.wine.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.wine, size: 18),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day});
  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day.dayLabel,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500)),
          Text('${day.openTime} - ${day.closeTime}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondaryText)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Mapa placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.wine.withAlpha(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagen estatica del mapa (placeholder)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/tarija_food.png', // Usando la imagen existente como placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Marcador del mapa
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.cardStrong,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.zone,
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Tarija, Bolivia',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.wine.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Como llegar',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.wine)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

