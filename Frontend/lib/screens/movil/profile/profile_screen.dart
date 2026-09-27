import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/profile/user_reviews_screen.dart';
import 'package:frontend/screens/movil/profile/user_support_screen.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';
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
  String? _statsError;

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
      final urlResenas = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/resenas/usuario/$idUsuario',
      );
      final resResenas = await http.get(
        urlResenas,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resResenas.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(resResenas.bodyBytes),
        );
        if (mounted) setState(() => _resenasCount = data.length);
      } else {
        throw Exception('No se pudieron cargar las estadísticas.');
      }
      final urlReservas = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/reservas/usuario/$idUsuario',
      );
      final resReservas = await http.get(
        urlReservas,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resReservas.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(resReservas.bodyBytes),
        );
        if (mounted) setState(() => _reservasCount = data.length);
      } else {
        throw Exception('No se pudieron cargar las estadísticas.');
      }
    } catch (e) {
      debugPrint('Error cargando estadisticas: $e');
      if (mounted)
        setState(
          () => _statsError =
              'No se pudieron cargar las estadísticas de tu perfil.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : 'Mi perfil';
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
                      color: ConsumerColors.ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_statsError != null) ...[
                    InlineErrorBanner(message: _statsError!),
                    const SizedBox(height: 16),
                  ],

                  // Identidad de la cuenta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ConsumerColors.card,
                      border: Border.all(color: ConsumerColors.line),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: ConsumerShadows.cardStrong,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: ConsumerColors.sage,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Center(
                            child: auth.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(23),
                                    child: Image.network(
                                      auth.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 78,
                                      height: 78,
                                    ),
                                  )
                                : Text(
                                    initial,
                                    style: const TextStyle(
                                      fontFamily: 'Fraunces',
                                      fontSize: 32,
                                      color: Colors.white,
                                    ),
                                  ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: ConsumerColors.ink,
                                      fontSize: 22,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (auth.email != null)
                                Text(
                                  auth.email!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(height: 12),
                              // Badges (Píldoras)
                              Row(
                                children: [
                                  _buildBadge(
                                    context,
                                    LucideIcons.calendar,
                                    '$_reservasCount Reservas',
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const UserReviewsScreen(),
                                        ),
                                      );
                                    },
                                    child: _buildBadge(
                                      context,
                                      Icons.star_rounded,
                                      '$_resenasCount Reseñas',
                                    ),
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    context,
                    Icons.star_rounded,
                    'Mis Reseñas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserReviewsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sección: Ayuda
                  Text(
                    'Ayuda',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    context,
                    LucideIcons.headset,
                    'Centro de ayuda',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserSupportScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botón cerrar sesión (adaptado al estilo minimalista)
                  _buildSettingRow(
                    context,
                    LucideIcons.logOut,
                    'Cerrar sesión',
                    isDestructive: true,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await auth.signOut();
                      if (auth.errorMessage != null && messenger.mounted) {
                        messenger.showMaterialBanner(
                          MaterialBanner(
                            content: Text(auth.errorMessage!),
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
        color: ConsumerColors.wineSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ConsumerColors.wine, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ConsumerColors.wineDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    IconData icon,
    String label, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? Colors.redAccent : ConsumerColors.ink;
    final iconColor = isDestructive ? Colors.redAccent : ConsumerColors.gold;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: ConsumerColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: ConsumerShadows.cardSoft,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 15, color: color),
              ),
            ),
            if (!isDestructive)
              const Icon(
                LucideIcons.chevronRight,
                color: ConsumerColors.inkSoft,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
