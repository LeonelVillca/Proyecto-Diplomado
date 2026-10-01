part of '../../../screens/movil/location/location_screen.dart';

class ListaRestaurantesMapa extends StatelessWidget {
  final ScrollController ctrl;
  final List<Restaurant> restaurants;
  final void Function(Restaurant) onCardTap;

  const ListaRestaurantesMapa({
    required this.ctrl,
    required this.restaurants,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: restaurants.length,
              itemBuilder: (_, i) => RestaurantMapCard(
                restaurant: restaurants[i],
                onTap: () => onCardTap(restaurants[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
