part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _PasoInformacionRestaurante on _PerfilRestauranteScreenState {
  Widget _buildInfo(bool narrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (narrow) ...[
        this._buildTextField(
          'Nombre del restaurante',
          _nombreCtrl,
          icon: LucideIcons.store,
        ),
        const SizedBox(height: 18),
        this._buildTextField(
          'Teléfono / WhatsApp',
          _telefonoCtrl,
          icon: LucideIcons.phone,
        ),
      ] else
        Row(
          children: [
            Expanded(
              child: this._buildTextField(
                'Nombre del restaurante',
                _nombreCtrl,
                icon: LucideIcons.store,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: this._buildTextField(
                'Teléfono / WhatsApp',
                _telefonoCtrl,
                icon: LucideIcons.phone,
              ),
            ),
          ],
        ),
      const SizedBox(height: 18),
      this._buildTextField(
        'Correo de contacto',
        _correoCtrl,
        icon: LucideIcons.mail,
      ),
      const SizedBox(height: 22),
      SelectorTiposComidaPerfil(pantalla: this),
      const SizedBox(height: 22),
      this._buildTextField(
        'Descripción',
        _descripcionCtrl,
        maxLines: 4,
        maxLength: 300,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${_descripcionCtrl.text.length} / 300',
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _descripcionCtrl.text.length > 280
                ? AdminTheme.warning
                : AdminTheme.textMuted,
          ),
        ),
      ),
    ],
  );
}

class PasoInformacionRestaurante extends StatelessWidget {
  const PasoInformacionRestaurante({
    super.key,
    required this.pantalla,
    required this.estrecho,
  });
  final _PerfilRestauranteScreenState pantalla;
  final bool estrecho;
  @override
  Widget build(BuildContext context) => pantalla._buildInfo(estrecho);
}
