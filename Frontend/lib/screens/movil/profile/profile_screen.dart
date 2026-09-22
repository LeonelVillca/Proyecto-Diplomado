import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/login/login_screen.dart';
import 'package:frontend/screens/movil/profile/user_reviews_screen.dart';
import 'package:frontend/screens/movil/profile/user_support_screen.dart';
import 'dart:convert';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/core/utils/network/api_endpoints.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _reservasCount = 0;
  int _resenasCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadisticas();
    });
  }

  Future<void> _cargarEstadisticas() async {
    final auth = AuthScope.of(context, listen: false);
    final idUsuario = auth.idUsuario;
    final token = auth.token;

    if (idUsuario == null) return;

    try {
      final urlResenas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/usuario/$idUsuario');
      final resResenas = await http.get(urlResenas, headers: {'Authorization': 'Bearer $token'});

      if (resResenas.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(resResenas.bodyBytes));
        if (mounted) setState(() => _resenasCount = data.length);
      }
      final urlReservas = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/usuario/$idUsuario');
      final resReservas = await http.get(urlReservas, headers: {'Authorization': 'Bearer $token'});

      if (resReservas.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(resReservas.bodyBytes));
        if (mounted) setState(() => _reservasCount = data.length);
      }
    } catch (e) {
      debugPrint('Error cargando estadisticas: $e');
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal
                  Text(
                    'Perfil',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 28,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta de perfil (estilo de la imagen pero con gradiente vino)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.wine, AppColors.wineDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.cardStrong,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: auth.photoUrl != null
                                ? ClipOval(child: Image.network(auth.photoUrl!, fit: BoxFit.cover, width: 72, height: 72))
                                : Icon(Icons.person_rounded, size: 40, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Tarija, Bolivia ',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Text('🇧🇴', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Badges (Píldoras)
                              Row(
                                children: [
                                  _buildBadge(context, Icons.calendar_month_rounded, '$_reservasCount Reservas'),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReviewsScreen()));
                                    },
                                    child: _buildBadge(context, Icons.star_rounded, '$_resenasCount Reseñas'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sección: Mi cuenta
                  Text(
                    'Mi cuenta',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(context, Icons.person_rounded, 'Editar perfil'),
                  _buildSettingRow(
                    context, 
                    Icons.star_rounded, 
                    'Mis Reseñas',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReviewsScreen()));
                    }
                  ),
                  const SizedBox(height: 24),

                  // Sección: Ayuda
                  Text(
                    'Ayuda',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    context, 
                    Icons.support_agent_rounded, 
                    'Centro de ayuda',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSupportScreen()));
                    }
                  ),
                  _buildSettingRow(context, Icons.info_outline_rounded, 'Términos y condiciones'),

                  const SizedBox(height: 32),

                  // Botón cerrar sesión (adaptado al estilo minimalista)
                  _buildSettingRow(
                    context, 
                    Icons.logout_rounded, 
                    'Cerrar todas las sesiones',
                    isDestructive: true,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await auth.signOut();
                      if (auth.errorMessage != null && messenger.mounted) {
                        messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
                      }
                    }
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

  Widget _buildBadge(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, IconData icon, String label, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? Colors.redAccent : AppColors.ink;
    final iconColor = isDestructive ? Colors.redAccent : AppColors.gold;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.cardSoft,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 15,
                  color: color,
                )
              ),
            ),
            if (!isDestructive)
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}
