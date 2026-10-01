part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _CampoFormulario on _PerfilRestauranteScreenState {
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textDark,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AdminTheme.bodyStyle.copyWith(color: AdminTheme.textDark),
          decoration: this._fieldDecoration(icon).copyWith(counterText: ''),
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(IconData? icon) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 17, color: AdminTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AdminTheme.error, width: 1.5),
    ),
  );
}
