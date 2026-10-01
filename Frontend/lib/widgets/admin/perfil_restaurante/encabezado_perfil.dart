part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _EncabezadoPerfil on _PerfilRestauranteScreenState {
  Widget _saveButton() => FilledButton.icon(
    onPressed: _isSaving ? null : _guardarPerfil,
    icon: _isSaving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : const Icon(LucideIcons.check, size: 18),
    label: Text(
      _isSaving ? 'Guardando...' : 'Guardar y actualizar',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: AdminTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shadowColor: const Color(0x47BE4B24),
      elevation: 5,
    ),
  );

  Widget _buildSection(
    String title,
    String subtitle,
    IconData icon,
    Color iconBackground,
    Color iconColor,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AdminTheme.titleStyle.copyWith(fontSize: 21),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
