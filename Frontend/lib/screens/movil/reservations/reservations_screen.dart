import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/models/movil/reservation.dart';
import 'package:frontend/widgets/movil/ui/app_empty_state.dart';
import 'package:frontend/widgets/movil/ui/app_section_header.dart';

/// Reservas del usuario: próximas citas e historial.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservations = RestauranteScope.of(context).reservations;
    final upcoming = reservations.where((r) => r.upcoming).toList();
    final past = reservations.where((r) => !r.upcoming).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _Header()),
        SliverToBoxAdapter(child: _Stats(upcoming: upcoming.length, past: past.length)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _notify(context, 'Nueva reserva — próximamente.'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Nueva reserva',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverToBoxAdapter(
          child: AppSectionHeader(title: 'Próximas', trailingLabel: '${upcoming.length}'),
        ),
        if (upcoming.isEmpty)
          const SliverToBoxAdapter(
            child: AppEmptyState(
              icon: Icons.event_available_rounded,
              title: 'Sin reservas próximas',
              description: 'Cuando reserves una mesa, aparecerá aquí.',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _ReservationCard(reservation: upcoming[index]),
              ),
              childCount: upcoming.length,
            ),
          ),
        if (past.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          const SliverToBoxAdapter(
            child: AppSectionHeader(title: 'Historial'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _ReservationCard(
                  reservation: past[index],
                  dimmed: true,
                ),
              ),
              childCount: past.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    ),
  );
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis reservas',
            style: GoogleFonts.montserrat(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Administra tus mesas reservadas',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.upcoming, required this.past});

  final int upcoming;
  final int past;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.event_available_rounded,
              value: '$upcoming',
              label: 'Próximas',
              emphasized: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.history_rounded,
              value: '$past',
              label: 'Historial',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.wine : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, this.dimmed = false});

  final Reservation reservation;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.62 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.cardSoft,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC97B3D), AppColors.wine],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                reservation.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reservation.zone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _MiniInfo(
                            icon: Icons.calendar_month_rounded,
                            text: reservation.date),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfo(
                            icon: Icons.schedule_rounded,
                            text: reservation.time),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfo(
                            icon: Icons.group_rounded,
                            text: '${reservation.guests} pers.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(upcoming: reservation.upcoming),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.gold),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final color = upcoming ? const Color(0xFF2E8B57) : AppColors.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        upcoming ? 'Confirmada' : 'Completada',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}