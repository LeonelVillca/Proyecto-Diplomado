part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _EncabezadoRecuperacionAdmin on _AdminLoginScreenState {
  Widget _buildRecoveryHeader(
    int step, {
    required VoidCallback onBack,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: authInkSoft,
            ),
            label: Text(
              step == 1 ? 'Volver al login' : 'Volver',
              style: GoogleFonts.manrope(
                color: authInkSoft,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isFilled ? authWine : const Color(0xFFE5DCD0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.piazzolla(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: authInk,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: authInkSoft,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
