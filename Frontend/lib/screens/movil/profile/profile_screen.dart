import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/screens/movil/profile/user_reviews_screen.dart';
import 'package:frontend/screens/movil/profile/user_support_screen.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';
import 'dart:convert';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/screens/movil/notifications/notifications_screen.dart';
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
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 88),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_statsError != null) ...[
                  InlineErrorBanner(message: _statsError!),
                  const SizedBox(height: 14),
                ],
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: ConsumerColors.sage,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: ConsumerShadows.cardStrong,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: auth.photoUrl == null
                            ? Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Image.network(
                                auth.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontFamily: 'Fraunces',
                                      fontSize: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 21, color: ConsumerColors.ink),
                      ),
                      if (auth.email != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 14,
                              color: ConsumerColors.inkSoft,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                auth.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: ConsumerColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ConsumerColors.wineSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              size: 13,
                              color: ConsumerColors.wine,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Comensal desde 2024',
                              style: TextStyle(
                                color: ConsumerColors.wineDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ConsumerColors.card,
                    border: Border.all(color: ConsumerColors.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          value: '$_reservasCount',
                          label: 'Reservas',
                        ),
                      ),
                      const _ProfileStatDivider(),
                      Expanded(
                        child: _ProfileStat(
                          value: '$_resenasCount',
                          label: 'Reseñas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserReviewsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const _ProfileStatDivider(),
                      const Expanded(
                        child: _ProfileStat(value: '0', label: 'Favoritos'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _ProfileSectionLabel('MI CUENTA'),
                const SizedBox(height: 8),
                _ProfileMenuGroup(
                  children: [
                    _ProfileMenuRow(
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: ConsumerColors.wine,
                      iconBackground: ConsumerColors.wineSoft,
                      label: 'Datos personales',
                    ),
                    _ProfileMenuRow(
                      icon: Icons.notifications_none_rounded,
                      iconColor: ConsumerColors.sage,
                      iconBackground: const Color(0xFFE8EFE1),
                      label: 'Notificaciones',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _ProfileSectionLabel('MÁS'),
                const SizedBox(height: 8),
                _ProfileMenuGroup(
                  children: [
                    _ProfileMenuRow(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF6968A5),
                      iconBackground: const Color(0xFFE9E8F6),
                      label: 'Centro de ayuda',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserSupportScreen(),
                        ),
                      ),
                    ),
                    _ProfileMenuRow(
                      icon: Icons.description_outlined,
                      iconColor: ConsumerColors.inkSoft,
                      iconBackground: ConsumerColors.paperDeep,
                      label: 'Términos y políticas',
                    ),
                    _ProfileMenuRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: ConsumerColors.inkSoft,
                      iconBackground: ConsumerColors.paperDeep,
                      label: 'Acerca de',
                      trailing: const Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: ConsumerColors.inkSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: auth.signOut,
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    side: const BorderSide(
                      color: Color(0xFFE7B8A8),
                      width: 1.2,
                    ),
                    foregroundColor: ConsumerColors.wineDark,
                    backgroundColor: ConsumerColors.card,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3),
    child: Text(
      label,
      style: const TextStyle(
        color: ConsumerColors.inkSoft,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.children});
  final List<_ProfileMenuRow> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ConsumerColors.card,
      border: Border.all(color: ConsumerColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 64,
                color: ConsumerColors.hairline,
              ),
          ],
        ],
      ),
    ),
  );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 61,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ConsumerColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                if (showDivider) const SizedBox(width: 6),
              ],
              if (trailing == null || showDivider)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD2C4B3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: ConsumerColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ConsumerColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 42,
    child: VerticalDivider(
      width: 1,
      thickness: 1,
      color: ConsumerColors.hairline,
    ),
  );
}
