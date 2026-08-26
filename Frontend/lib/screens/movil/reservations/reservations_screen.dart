import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis reservas', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28)),
                  const SizedBox(height: 24),
                  
                  // Tarjetas de estadisticas
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(context, '0', 'Próximas', Icons.event_available_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(context, '0', 'Historial', Icons.history_rounded)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Estado vacio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.cardSoft),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: AppColors.paperDeep, shape: BoxShape.circle),
                          child: const Icon(Icons.calendar_today_rounded, size: 36, color: AppColors.wine),
                        ),
                        const SizedBox(height: 24),
                        Text('Sin reservas próximas', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text('Parece que aún no tienes planes. ¡Descubre un nuevo lugar para comer hoy!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.wine,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('+ Nueva reserva', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.cardSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.wine, size: 24),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}