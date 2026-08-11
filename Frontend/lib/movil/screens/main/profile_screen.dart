import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/ui/app_avatar.dart';

/// Sección "Usuarios": perfil de la cuenta, accesos rápidos y cierre de sesión.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final favorites = FavoritesScope.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuarios',
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tu cuenta y tus ajustes',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _ProfileCard(
              name: auth.displayName,
              email: auth.email,
              photoUrl: auth.photoUrl,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _StatsRow(favoritesCount: favorites.count),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        const SliverToBoxAdapter(child: _MenuSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.wine,
                  side: const BorderSide(color: Color(0x665C1A2E)),
                  backgroundColor: AppColors.wine.withAlpha(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: Text(
                  'Cerrar sesión',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wine,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String? name;
  final String? email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C1A2E), Color(0xFF2A0B17)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.cardStrong,
      ),
      child: Row(
        children: [
          AppAvatar(
            name: name,
            photoUrl: photoUrl,
            radius: 28,
            color: AppColors.sunset,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Chapaco',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? 'Invitado · sin sesión',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit_rounded,
              color: Colors.white.withAlpha(200), size: 18),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.favoritesCount});

  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(value: '0', label: 'Reservas', icon: Icons.event_rounded)),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            value: '$favoritesCount',
            label: 'Favoritos',
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _MiniStat(value: '0', label: 'Reseñas', icon: Icons.rate_review_rounded)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.gold),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.settings_rounded, 'Configuración'),
      (Icons.notifications_rounded, 'Notificaciones'),
      (Icons.help_outline_rounded, 'Ayuda y soporte'),
      (Icons.share_rounded, 'Compartir la app'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final (icon, label) in items)
            _MenuTile(
              icon: icon,
              label: label,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label — próximamente.'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.wine.withAlpha(12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.wine),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.secondaryText, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}