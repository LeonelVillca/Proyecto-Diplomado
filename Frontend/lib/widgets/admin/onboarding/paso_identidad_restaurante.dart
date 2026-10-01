part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

class PasoIdentidadRestaurante extends StatelessWidget {
  const PasoIdentidadRestaurante({
    super.key,
    required this.pantalla,
    required this.mobile,
  });
  final _OnboardingRestauranteScreenState pantalla;
  final bool mobile;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso1(mobile);
}

extension _Onboarding_paso_identidad_restaurante
    on _OnboardingRestauranteScreenState {
  Widget _buildPaso1(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      this._stepHeading(
        0,
        'Identidad',
        'La primera impresión ',
        'se come con los ojos.',
        'Así verán tu restaurante los comensales por primera vez. Tómate tu tiempo con esto.',
      ),
      this._sectionCard(
        'Foto de portada',
        'La imagen principal de tu perfil público.',
        LucideIcons.image,
        AdminTheme.primaryLight,
        AdminTheme.primaryColor,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            this._coverPicker(),
            const SizedBox(height: 22),
            const Divider(color: AdminTheme.rowBorder),
            const SizedBox(height: 16),
            this._logoPicker(),
          ],
        ),
      ),
      this._sectionCard(
        'Datos del restaurante',
        'Cómo se llama y qué se sirve en tu casa.',
        LucideIcons.store,
        AdminTheme.accentSoft,
        AdminTheme.accentColor,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            this._buildTextField(
              'Nombre del restaurante',
              _nombreCtrl,
              icon: LucideIcons.store,
              hint: 'ej. Casa Valcázar',
            ),
            const SizedBox(height: 18),
            this._buildTiposComidaSelector(),
            const SizedBox(height: 18),
            this._buildTextField(
              'Descripción',
              _descripcionCtrl,
              maxLines: 4,
              hint: 'Cuéntales tu historia',
            ),
            const SizedBox(height: 5),
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
            const SizedBox(height: 18),
            if (mobile) ...[
              this._buildTextField(
                'Teléfono / WhatsApp',
                _telefonoCtrl,
                icon: LucideIcons.phone,
                hint: 'ej. 65473914',
              ),
              const SizedBox(height: 18),
              this._buildTextField(
                'Correo público',
                _correoCtrl,
                icon: LucideIcons.mail,
                hint: 'contacto@turestaurante.com',
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: this._buildTextField(
                      'Teléfono / WhatsApp',
                      _telefonoCtrl,
                      icon: LucideIcons.phone,
                      hint: 'ej. 65473914',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: this._buildTextField(
                      'Correo público',
                      _correoCtrl,
                      icon: LucideIcons.mail,
                      hint: 'contacto@turestaurante.com',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );

  Widget _coverPicker() => MouseRegion(
    onEnter: (_) => setState(() => _coverHovered = true),
    onExit: (_) => setState(() => _coverHovered = false),
    child: _selectedImageBytes == null
        ? InkWell(
            onTap: this._pickImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              decoration: BoxDecoration(
                color: AdminTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD5C9B8), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AdminTheme.shadowSm,
                    ),
                    child: const Icon(
                      LucideIcons.cloudUpload,
                      size: 25,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Sube la foto de portada',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Haz clic aquí · JPG, PNG o WEBP',
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.successSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 13,
                            color: AdminTheme.success,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Portada cargada',
                            style: TextStyle(
                              color: AdminTheme.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    color: _coverHovered
                        ? const Color(0x661C1611)
                        : Colors.transparent,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity:
                          _coverHovered ||
                              MediaQuery.sizeOf(context).width <= 640
                          ? 1
                          : 0,
                      child: Wrap(
                        spacing: 10,
                        children: [
                          this._coverAction(
                            LucideIcons.camera,
                            'Cambiar',
                            this._pickImage,
                          ),
                          this._coverAction(
                            LucideIcons.trash2,
                            'Quitar',
                            () => setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );

  Widget _coverAction(IconData icon, String label, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: label == 'Quitar'
              ? AdminTheme.error
              : AdminTheme.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
      );

  Widget _logoPicker() => Row(
    children: [
      InkWell(
        onTap: this._pickLogo,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AdminTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminTheme.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedLogoBytes == null
              ? const Icon(
                  LucideIcons.image,
                  size: 25,
                  color: AdminTheme.primaryColor,
                )
              : Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logo del restaurante',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Necesario para activar tu perfil.',
              style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: this._pickLogo,
              icon: const Icon(LucideIcons.camera, size: 15),
              label: Text(
                _selectedLogoBytes == null ? 'Subir logo' : 'Cambiar logo',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AdminTheme.primaryColor,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
