part of '../../../screens/movil/home/home_screen.dart';

class SinResultadosInicio extends StatelessWidget {
  const SinResultadosInicio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            LucideIcons.searchX,
            size: 52,
            color: _C.textSoft.withAlpha(120),
          ),
          const SizedBox(height: 14),
          Text(
            'No encontramos resultados',
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
