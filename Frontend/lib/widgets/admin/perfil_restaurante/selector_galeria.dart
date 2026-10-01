part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _SelectorGaleria on _PerfilRestauranteScreenState {
  Widget _buildGaleriaBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.background,
          border: Border.all(
            color: const Color(0xFFD5C9B8),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 17, color: AdminTheme.gold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Mínimo 5 fotos de alta calidad para publicar tu restaurante ante los comensales.',
                style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 620 ? 3 : 4;
          final total = _existingGallery.length + _selectedGalleryBytes.length;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: total + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index == total) {
                return this._buildAddPhotoTile();
              }
              if (index < _existingGallery.length) {
                final image = _existingGallery[index];
                return this._buildGaleriaItem(
                  networkUrl: image['url']?.toString(),
                  imageId: (image['id'] as num?)?.toInt(),
                );
              }
              final selectedIndex = index - _existingGallery.length;
              return this._buildGaleriaItem(
                bytes: _selectedGalleryBytes[selectedIndex],
                index: selectedIndex,
              );
            },
          );
        },
      ),
    ],
  );

  Widget _buildAddPhotoTile() => InkWell(
    onTap: _pickGallery,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: AdminTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5C9B8), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.plus,
            size: 24,
            color: AdminTheme.primaryColor,
          ),
          const SizedBox(height: 8),
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

  Widget _buildGaleriaItem({
    String? networkUrl,
    Uint8List? bytes,
    int? index,
    int? imageId,
  }) {
    var hovered = false;
    return StatefulBuilder(
      builder: (context, localSetState) => MouseRegion(
        onEnter: (_) => localSetState(() => hovered = true),
        onExit: (_) => localSetState(() => hovered = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: hovered ? 1.07 : 1,
                duration: const Duration(milliseconds: 400),
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : networkUrl != null
                    ? Image.network(
                        this._mediaUrl(networkUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            this._buildCoverPlaceholder(),
                      )
                    : this._buildCoverPlaceholder(),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: hovered ? const Color(0x801C1611) : Colors.transparent,
              ),
              IgnorePointer(
                ignoring: !hovered && MediaQuery.sizeOf(context).width > 720,
                child: AnimatedOpacity(
                  opacity: hovered || MediaQuery.sizeOf(context).width <= 720
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Quitar fotografía',
                          onPressed: () => setState(() {
                            if (index != null) {
                              _selectedGallery.removeAt(index);
                              _selectedGalleryBytes.removeAt(index);
                            } else if (imageId != null) {
                              _existingGallery.removeWhere(
                                (image) =>
                                    (image['id'] as num?)?.toInt() == imageId,
                              );
                              if (!_deletedGalleryIds.contains(imageId)) {
                                _deletedGalleryIds.add(imageId);
                              }
                            }
                            _isDirty = true;
                          }),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 17,
                            color: AdminTheme.error,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
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
    );
  }

  String _mediaUrl(String url) =>
      url.startsWith('http') ? url : '${ApiEndpoints.baseUrl}$url';
}

class SelectorGaleriaRestaurante extends StatelessWidget {
  const SelectorGaleriaRestaurante({super.key, required this.pantalla});
  final _PerfilRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildGaleriaBlock();
}
