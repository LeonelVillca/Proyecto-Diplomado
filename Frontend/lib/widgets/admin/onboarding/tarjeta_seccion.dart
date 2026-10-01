part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

extension _TarjetaSeccionOnboarding on _OnboardingRestauranteScreenState {
  Widget _sectionCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconBg,
    Color iconColor,
    Widget content,
  ) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AdminTheme.border),
      boxShadow: AdminTheme.shadowSm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AdminTheme.titleStyle.copyWith(fontSize: 19),
                  ),
                  Text(
                    subtitle,
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        content,
      ],
    ),
  );
}
