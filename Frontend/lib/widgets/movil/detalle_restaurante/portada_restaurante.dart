part of '../../../screens/movil/restaurantes/restaurant_detail_screen.dart';

class PortadaRestaurante extends StatefulWidget {
  final Restaurant restaurant;
  const PortadaRestaurante({required this.restaurant});

  @override
  State<PortadaRestaurante> createState() => _EstadoPortadaRestaurante();
}

class _EstadoPortadaRestaurante extends State<PortadaRestaurante> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.restaurant.gallery.isNotEmpty
        ? widget.restaurant.gallery
        : (widget.restaurant.photoUrl != null
              ? [widget.restaurant.photoUrl!]
              : <String>[]);
    final cover = images.isNotEmpty && _selectedIndex < images.length
        ? images[_selectedIndex]
        : (images.isNotEmpty ? images.first : null);

    return Container(
      height: 244,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ConsumerColors.wineSoft,
        image: cover != null
            ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        children: [
          // Degradado superior para que se vean los botones
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),

          // Miniaturas de galeria (solo si hay fotos)
          if (images.length > 1)
            Positioned(
              bottom: 36,
              // Reserva el lado izquierdo para el botón de volver de la barra.
              left: 76,
              child: Row(
                children: List.generate(images.length > 4 ? 4 : images.length, (
                  idx,
                ) {
                  final isLastAndMore = idx == 3 && images.length > 4;
                  final isSelected = _selectedIndex == idx && !isLastAndMore;
                  return GestureDetector(
                    onTap: () {
                      if (isLastAndMore) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GaleriaScreen(images: images, initialIndex: 3),
                          ),
                        );
                      } else {
                        setState(() {
                          _selectedIndex = idx;
                        });
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? ConsumerColors.wine
                              : Colors.white,
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(images[idx]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isLastAndMore
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+${images.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
