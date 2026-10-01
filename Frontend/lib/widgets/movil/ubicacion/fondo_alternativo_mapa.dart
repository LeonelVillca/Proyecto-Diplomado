part of '../../../screens/movil/location/location_screen.dart';

class FondoAlternativoMapa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2ECDF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.map, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              'Tarija · Bolivia',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'El mapa estará disponible en el dispositivo móvil',
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 12,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel inferior ───────────────────────────────────────────────────────────
