import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';

/// Cabecera cinematica con imagen principal y tira de miniaturas interactiva.
/// Al tocar una miniatura la imagen principal cambia con animacion Fade.
class DetailHero extends StatefulWidget {
  const DetailHero({super.key, required this.images, required this.restaurantName});

  final List<String> images;
  final String restaurantName;

  @override
  State<DetailHero> createState() => _DetailHeroState();
}

class _DetailHeroState extends State<DetailHero> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Imagen principal con transicion animada
          if (widget.images.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _HeroImage(key: ValueKey(_selected), path: widget.images[_selected]),
            )
          else
            Container(color: AppColors.wine),

          // Degradado inferior oscuro
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(180)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),

          // Control flotante de navegación
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _GlassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
              ),
            ),
          ),

          // Tira de miniaturas en la parte inferior de la imagen
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: _ThumbnailStrip(
              images: widget.images,
              selected: _selected,
              onSelect: (i) => setState(() => _selected = i),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final isNetwork = path.startsWith('http') || path.startsWith('/');
    return SizedBox.expand(
      child: isNetwork
        ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.wine))
        : Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.wine)),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.images, required this.selected, required this.onSelect});
  final List<String> images;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1, // +1 para el boton de ver todas
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == images.length) {
            // Boton de "Ver todas"
            return GestureDetector(
              onTap: () {
                // TODO: Navegar a galeria completa
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(60), width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                    SizedBox(height: 2),
                    Text('+10', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: images[i].startsWith('http') || images[i].startsWith('/')
                  ? Image.network(images[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.wine.withAlpha(80)))
                  : Image.asset(images[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.wine.withAlpha(80))),
              ),
            ),
          );
        },
      ),
    );
  }
}
