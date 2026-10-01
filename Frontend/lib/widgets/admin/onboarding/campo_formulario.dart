part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

extension _CampoFormularioOnboarding on _OnboardingRestauranteScreenState {
  Widget _fieldLabel(String label, {String? suffix}) => RichText(
    text: TextSpan(
      style: AdminTheme.bodyStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AdminTheme.textDark,
      ),
      children: [
        TextSpan(text: label),
        if (suffix != null)
          TextSpan(
            text: '  $suffix',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
          ),
      ],
    ),
  );

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      this._fieldLabel(label),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: AdminTheme.bodyStyle.copyWith(
          fontSize: 14,
          color: AdminTheme.textDark,
        ),
        decoration: this._inputDecoration(icon).copyWith(hintText: hint),
      ),
    ],
  );

  InputDecoration _inputDecoration(IconData? icon) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 17, color: AdminTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    hintStyle: AdminTheme.bodyStyle.copyWith(color: const Color(0xFFB8ADA2)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.border, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.primaryColor, width: 1.5),
    ),
  );
}
