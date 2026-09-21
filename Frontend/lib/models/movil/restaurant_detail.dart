/// Modelos de detalle del restaurante (menú, platos, reseñas y horarios).
/// Cuando exista el endpoint real, solo se cambia el repositorio HTTP.

class DishItem {
  const DishItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.available,
    this.photoUrl,
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final bool available;
  final String? photoUrl;
}

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    this.ownerReply,
  });

  final String id;
  final String authorName;
  final int rating;
  final String comment;
  final String date;
  final String? ownerReply;
}

class ScheduleDay {
  const ScheduleDay({
    required this.dayLabel,
    required this.openTime,
    required this.closeTime,
  });

  final String dayLabel;
  final String openTime;
  final String closeTime;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const List<String> mockGalleryImages = [
  'assets/restaurant_hero.webp',
  'assets/tarija_food.webp',
  'assets/dining_couple.webp',
  'assets/restaurant_hero.webp',
  'assets/tarija_food.webp',
];

const List<DishItem> mockDishes = [
  DishItem(id: 'd1', name: 'Sopa de Mani', price: 35, description: 'Caldo tarijeño con mani tostado y verduras de estacion.', category: 'Entradas', available: true, photoUrl: 'assets/tarija_food.webp'),
  DishItem(id: 'd2', name: 'Saice Tarijeño', price: 55, description: 'Plato tipico con carne molida, papa y maiz chapaco.', category: 'Platos Fuertes', available: true, photoUrl: 'assets/tarija_food.webp'),
  DishItem(id: 'd3', name: 'Costillar a la Brasa', price: 110, description: 'Costillar de cerdo al carbon con papa cocida y ensalada.', category: 'Platos Fuertes', available: true, photoUrl: 'assets/tarija_food.webp'),
  DishItem(id: 'd4', name: 'Vino Tinto Reserva', price: 80, description: 'Vino de los Cintis, cosecha 2021, varietal Cabernet Sauvignon.', category: 'Vinos y Bebidas', available: true, photoUrl: 'assets/tarija_food.webp'),
  DishItem(id: 'd5', name: 'Empanadas Salteñas', price: 20, description: 'Empanadas criollas de carne picada con pasas y aceituna.', category: 'Entradas', available: false, photoUrl: 'assets/tarija_food.webp'),
  DishItem(id: 'd6', name: 'Mousse de Chocolate', price: 30, description: 'Postre artesanal con cacao boliviano y crema chantilly.', category: 'Postres', available: true, photoUrl: 'assets/tarija_food.webp'),
];

const List<ReviewItem> mockReviews = [
  ReviewItem(id: 'rv1', authorName: 'Carla Mendoza', rating: 5, comment: 'Una experiencia increible. El ambiente es romantico y el saice es el mejor de Tarija.', date: 'Hace 2 dias', ownerReply: 'Muchas gracias, Carla. Es un placer recibirte.'),
  ReviewItem(id: 'rv2', authorName: 'Roberto Salinas', rating: 4, comment: 'Muy buen lugar, el vino de la casa es excelente. El servicio podria ser un poco mas rapido.', date: 'Hace 1 semana'),
  ReviewItem(id: 'rv3', authorName: 'Luisa Torrico', rating: 5, comment: 'Los mejores cortes de carne que probe en la ciudad. Definitivamente volvere con mi familia.', date: 'Hace 2 semanas'),
];

const List<ScheduleDay> mockSchedule = [
  ScheduleDay(dayLabel: 'Lunes a Viernes', openTime: '12:00', closeTime: '23:00'),
  ScheduleDay(dayLabel: 'Sabado', openTime: '11:00', closeTime: '00:00'),
  ScheduleDay(dayLabel: 'Domingo', openTime: '11:00', closeTime: '22:00'),
];
