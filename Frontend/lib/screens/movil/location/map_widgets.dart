import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/movil/location/map_data.dart';

/// Píldora flotante de filtro rápido (personas + horario).
class MapFilterPill extends StatelessWidget {
  const MapFilterPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 18, color: kWineColor),
          const SizedBox(width: 6),
          Text('2  ·  Esta noche - 19:00', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}

/// Barra de búsqueda flotante.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Colors.black45, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(
                hintText: 'Buscar restaurante o zona...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kWineColor, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.tune, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Chips de categorías horizontales.
class MapFilterChips extends StatefulWidget {
  const MapFilterChips({super.key});

  @override
  State<MapFilterChips> createState() => _MapFilterChipsState();
}

class _MapFilterChipsState extends State<MapFilterChips> {
  final List<String> _cats = ['🍷 Vinos', '🔥 Parrilla', '❤️ Romántico', '☕ Brunch', '🌍 Internacional', '🥗 Tarijeña'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? kWineColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(_cats[i], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.black87)),
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta de restaurante dentro del bottom sheet.
class RestaurantMapCard extends StatelessWidget {
  final MapRestaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantMapCard({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: kWineColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: kWineColor, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.nombre, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(restaurant.tipo, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: kGoldColor, size: 15),
                      const SizedBox(width: 3),
                      Text('${restaurant.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text(restaurant.precio, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
