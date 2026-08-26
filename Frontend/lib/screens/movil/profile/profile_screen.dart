import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName ?? 'Chapaco';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                children: [
                  // Tarjeta de perfil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.wine, AppColors.wineDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.cardStrong,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: Center(
                            child: auth.photoUrl != null
                                ? ClipOval(child: Image.network(auth.photoUrl!, fit: BoxFit.cover, width: 80, height: 80))
                                : Text(initial, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(displayName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(auth.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(context, '0', 'Reservas'),
                            Container(width: 1, height: 30, color: Colors.white30),
                            _buildStat(context, '0', 'Favoritos'),
                            Container(width: 1, height: 30, color: Colors.white30),
                            _buildStat(context, '0', 'Reseñas'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Lista de ajustes
                  _buildSettingRow(context, Icons.person_outline_rounded, 'Editar perfil'),
                  _buildSettingRow(context, Icons.notifications_none_rounded, 'Notificaciones'),
                  _buildSettingRow(context, Icons.payment_rounded, 'Métodos de pago'),
                  const SizedBox(height: 16),
                  _buildSettingRow(context, Icons.support_agent_rounded, 'Centro de ayuda'),
                  _buildSettingRow(context, Icons.article_outlined, 'Términos y condiciones'),

                  const SizedBox(height: 32),

                  // Botón cerrar sesión
                  OutlinedButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.wine, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text('Cerrar sesión', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.wine, fontSize: 14)),
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

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildSettingRow(BuildContext context, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.cardSoft),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.paperDeep, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.inkSoft, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 20),
        ],
      ),
    );
  }
}