part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

class SelectorGaleria extends StatelessWidget {
  const SelectorGaleria({super.key, required this.pantalla});
  final _OnboardingRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildGaleriaBlock();
}

extension _Onboarding_selector_galeria on _OnboardingRestauranteScreenState {
  Widget _buildGaleriaBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 13,
        children: [
          SizedBox(
            width: 315,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, size: 16, color: AdminTheme.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sube al menos 5 fotos de alta calidad para activar tu perfil.',
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          this._galleryCount(),
        ],
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth <= 640 ? 3 : 5;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedGalleryBytes.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index == _selectedGalleryBytes.length)
                return this._addPhotoTile();
              return this._galleryPhoto(index);
            },
          );
        },
      ),
    ],
  );

  Widget _galleryCount() {
    final count = _selectedGalleryBytes.length;
    final done = count >= 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count de 5 fotos',
          style: AdminTheme.bodyStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AdminTheme.textDark,
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            width: 130,
            height: 8,
            child: Stack(
              children: [
                Container(color: AdminTheme.rowBorder),
                AnimatedFractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (count / 5).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    color: done ? AdminTheme.success : AdminTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (done) ...[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.successSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.checkCheck,
                  size: 13,
                  color: AdminTheme.success,
                ),
                SizedBox(width: 4),
                Text(
                  '¡Listo!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _galleryPhoto(int index) {
    var hovered = false;
    return StatefulBuilder(
      builder: (context, localSetState) => MouseRegion(
        onEnter: (_) => localSetState(() => hovered = true),
        onExit: (_) => localSetState(() => hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: hovered ? 1.07 : 1,
                duration: const Duration(milliseconds: 400),
                child: Image.memory(
                  _selectedGalleryBytes[index],
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: hovered ? const Color(0x801C1611) : Colors.transparent,
              ),
              IgnorePointer(
                ignoring: !hovered && MediaQuery.sizeOf(context).width > 640,
                child: AnimatedOpacity(
                  opacity: hovered || MediaQuery.sizeOf(context).width <= 640
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Eliminar foto',
                          onPressed: () => setState(() {
                            _selectedGallery.removeAt(index);
                            _selectedGalleryBytes.removeAt(index);
                          }),
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: AdminTheme.error,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
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
    );
  }

  Widget _addPhotoTile() => InkWell(
    onTap: this._pickGallery,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD5C9B8), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.plus,
            size: 23,
            color: AdminTheme.primaryColor,
          ),
          const SizedBox(height: 7),
          Text(
            'Añadir foto',
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminTheme.primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}
