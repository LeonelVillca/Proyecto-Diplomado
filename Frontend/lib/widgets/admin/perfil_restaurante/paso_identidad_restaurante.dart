part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _PasoIdentidadRestaurante on _PerfilRestauranteScreenState {
  Widget _buildIdentity() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 266 : 250,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _coverHovered = true),
                  onExit: (_) => setState(() => _coverHovered = false),
                  child: SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_selectedImageBytes != null)
                            Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          else if (_restaurante!.fotoPortada != null)
                            Image.network(
                              this._mediaUrl(_restaurante!.fotoPortada!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  this._buildCoverPlaceholder(),
                            )
                          else
                            this._buildCoverPlaceholder(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: Colors.black.withValues(
                              alpha: _coverHovered ? .32 : .06,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _coverHovered || compact ? 1 : 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .94,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.camera,
                                            size: 16,
                                            color: AdminTheme.primaryDark,
                                          ),
                                          SizedBox(width: 7),
                                          Text(
                                            'Cambiar portada',
                                            style: TextStyle(
                                              color: AdminTheme.primaryDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 162,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AdminTheme.shadowMd,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: ColoredBox(
                              color: AdminTheme.primaryColor,
                              child: _selectedLogoBytes != null
                                  ? Image.memory(
                                      _selectedLogoBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : _restaurante!.logo != null
                                  ? Image.network(
                                      this._mediaUrl(_restaurante!.logo!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          this._logoInitial(),
                                    )
                                  : this._logoInitial(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        bottom: -4,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            onPressed: _pickLogo,
                            tooltip: 'Cambiar logo',
                            icon: const Icon(
                              LucideIcons.camera,
                              size: 15,
                              color: AdminTheme.primaryColor,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  Positioned(
                    top: 222,
                    left: 144,
                    right: 0,
                    child: this._coverHint(),
                  ),
              ],
            ),
          ),
          if (compact) ...[const SizedBox(height: 4), this._coverHint()],
        ],
      );
    },
  );

  Widget _buildCoverPlaceholder() => Container(
    color: AdminTheme.surfaceMuted,
    alignment: Alignment.center,
    child: const Icon(LucideIcons.image, size: 42, color: AdminTheme.textLight),
  );

  Widget _logoInitial() => Center(
    child: Text(
      _nombreCtrl.text.trim().isEmpty
          ? '?'
          : _nombreCtrl.text.trim().substring(0, 1).toUpperCase(),
      style: AdminTheme.titleStyle.copyWith(fontSize: 42, color: Colors.white),
    ),
  );

  Widget _coverHint() => Row(
    children: [
      const Icon(LucideIcons.info, size: 16, color: AdminTheme.gold),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          'La portada se muestra en tu perfil público y en la app de comensales.',
          style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
        ),
      ),
    ],
  );
}

class PasoIdentidadRestaurante extends StatelessWidget {
  const PasoIdentidadRestaurante({super.key, required this.pantalla});
  final _PerfilRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildIdentity();
}
