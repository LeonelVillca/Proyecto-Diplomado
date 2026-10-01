part of '../../../screens/movil/location/location_screen.dart';

class FiltroCocinaMapa extends StatelessWidget {
  const FiltroCocinaMapa({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: Icon(icon, size: 15),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : ConsumerColors.inkSoft,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        selectedColor: ConsumerColors.wine,
        side: BorderSide(
          color: selected ? ConsumerColors.wine : const Color(0xFFE8E0D4),
        ),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

// ── Modal de Restaurante al tocar Marcador ──────────────────────────────────
