part of '../../../screens/movil/restaurantes/restaurant_detail_screen.dart';

class BotonRedondoDetalle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const BotonRedondoDetalle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ConsumerColors.paper.withOpacity(0.96),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: ConsumerColors.ink, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}
