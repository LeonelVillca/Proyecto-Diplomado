part of '../../../screens/movil/home/home_screen.dart';

class BarraBusquedaInicio extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  const BarraBusquedaInicio({
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 14,
                color: _C.text,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar restaurantes...',
                hintStyle: const TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 14,
                  color: _C.textSoft,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: _C.textSoft,
                  size: 18,
                ),
                filled: true,
                fillColor: _C.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: ConsumerColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: ConsumerColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: ConsumerColors.wine),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filled(
            tooltip: 'Filtrar por categoría',
            onPressed: onFilterTap,
            style: IconButton.styleFrom(
              backgroundColor: _C.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 19),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Chips de categoría
// ──────────────────────────────────────────────────────────────────────
