/// Data model for a restaurant listing on the home screen.
class RestaurantModel {
  final String id;
  final String name;
  final String cuisineType;
  final double rating;
  final int reviewCount;
  final String deliveryTime; // e.g. "60–70 mins"
  final double distanceKm;
  final String offerText; // e.g. "Flat ₹100 OFF above ₹499"
  final int offerAbove; // 499 | 799 | 999
  final int offerAmount; // flat discount amount
  final String heroImage; // asset path for banner
  final String topDishLabel; // e.g. "Chilli Shrimp · ₹499"
  final bool isFeatured;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisineType,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.distanceKm,
    required this.offerText,
    required this.offerAbove,
    required this.offerAmount,
    required this.heroImage,
    required this.topDishLabel,
    this.isFeatured = false,
  });
}

/// Static list of dummy restaurants.
const List<RestaurantModel> kRestaurants = [
  RestaurantModel(
    id: 'r1',
    name: 'Restaurant 1',
    cuisineType: 'Seafood · Coastal',
    rating: 4.3,
    reviewCount: 2400,
    deliveryTime: '60–70 mins',
    distanceKm: 1.2,
    offerText: 'Flat ₹100 OFF above ₹499',
    offerAbove: 499,
    offerAmount: 100,
    heroImage: 'assets/images/shrimp_dish_1.png',
    topDishLabel: 'Chilli Shrimp · ₹499',
    isFeatured: true,
  ),
  RestaurantModel(
    id: 'r2',
    name: 'Restaurant 2',
    cuisineType: 'Seafood · Grill',
    rating: 4.1,
    reviewCount: 1800,
    deliveryTime: '65–80 mins',
    distanceKm: 2.1,
    offerText: 'Flat ₹150 OFF above ₹799',
    offerAbove: 799,
    offerAmount: 150,
    heroImage: 'assets/images/shrimp_dish_2.png',
    topDishLabel: 'Garlic Butter Prawns · ₹649',
    isFeatured: true,
  ),
  RestaurantModel(
    id: 'r3',
    name: 'Restaurant 3',
    cuisineType: 'Seafood · Pan Asian',
    rating: 4.5,
    reviewCount: 3100,
    deliveryTime: '50–65 mins',
    distanceKm: 0.9,
    offerText: 'Flat ₹200 OFF above ₹999',
    offerAbove: 999,
    offerAmount: 200,
    heroImage: 'assets/images/shrimp_dish_3.png',
    topDishLabel: 'Tiger Prawn Masala · ₹799',
  ),
  RestaurantModel(
    id: 'r4',
    name: 'Restaurant 4',
    cuisineType: 'Seafood · Mughlai',
    rating: 3.9,
    reviewCount: 870,
    deliveryTime: '70–85 mins',
    distanceKm: 3.4,
    offerText: 'Flat ₹80 OFF above ₹499',
    offerAbove: 499,
    offerAmount: 80,
    heroImage: 'assets/images/shrimp_dish_4.png',
    topDishLabel: 'Handi Prawn Curry · ₹549',
  ),
  RestaurantModel(
    id: 'r5',
    name: 'Restaurant 5',
    cuisineType: 'Seafood · Kerala',
    rating: 4.4,
    reviewCount: 2200,
    deliveryTime: '55–70 mins',
    distanceKm: 1.8,
    offerText: 'Flat ₹120 OFF above ₹799',
    offerAbove: 799,
    offerAmount: 120,
    heroImage: 'assets/images/shrimp_dish_5.png',
    topDishLabel: 'Kerala Prawn Curry · ₹599',
  ),
  RestaurantModel(
    id: 'r6',
    name: 'Restaurant 6',
    cuisineType: 'Seafood · Chinese',
    rating: 4.0,
    reviewCount: 1400,
    deliveryTime: '60–75 mins',
    distanceKm: 2.6,
    offerText: 'Flat ₹250 OFF above ₹999',
    offerAbove: 999,
    offerAmount: 250,
    heroImage: 'assets/images/shrimp_dish_6.png',
    topDishLabel: 'Chilli Garlic Shrimp · ₹549',
  ),
  RestaurantModel(
    id: 'r7',
    name: 'Restaurant 7',
    cuisineType: 'Seafood · Continental',
    rating: 4.2,
    reviewCount: 960,
    deliveryTime: '75–90 mins',
    distanceKm: 4.0,
    offerText: 'Flat ₹100 OFF above ₹499',
    offerAbove: 499,
    offerAmount: 100,
    heroImage: 'assets/images/shrimp_fresh_pile.png',
    topDishLabel: 'Lemon Butter Shrimp · ₹699',
  ),
  RestaurantModel(
    id: 'r8',
    name: 'Restaurant 8',
    cuisineType: 'Seafood · Thai',
    rating: 4.6,
    reviewCount: 4100,
    deliveryTime: '50–60 mins',
    distanceKm: 1.5,
    offerText: 'Flat ₹180 OFF above ₹799',
    offerAbove: 799,
    offerAmount: 180,
    heroImage: 'assets/images/shrimp_lemon_herb.png',
    topDishLabel: 'Thai Basil Prawns · ₹749',
    isFeatured: true,
  ),
  RestaurantModel(
    id: 'r9',
    name: 'Restaurant 9',
    cuisineType: 'Seafood · Goan',
    rating: 3.8,
    reviewCount: 640,
    deliveryTime: '80–100 mins',
    distanceKm: 5.2,
    offerText: 'Flat ₹300 OFF above ₹999',
    offerAbove: 999,
    offerAmount: 300,
    heroImage: 'assets/images/shrimp_tiger_trio.png',
    topDishLabel: 'Goan Prawn Curry · ₹649',
  ),
  RestaurantModel(
    id: 'r10',
    name: 'Restaurant 10',
    cuisineType: 'Seafood · Fusion',
    rating: 4.3,
    reviewCount: 1950,
    deliveryTime: '60–75 mins',
    distanceKm: 2.9,
    offerText: 'Flat ₹130 OFF above ₹499',
    offerAbove: 499,
    offerAmount: 130,
    heroImage: 'assets/images/shrimp_cooked_duo.png',
    topDishLabel: 'Fusion Shrimp Tacos · ₹579',
  ),
  RestaurantModel(
    id: 'r11',
    name: 'Restaurant 11',
    cuisineType: 'Seafood · Tandoor',
    rating: 4.1,
    reviewCount: 1100,
    deliveryTime: '65–80 mins',
    distanceKm: 3.1,
    offerText: 'Flat ₹200 OFF above ₹999',
    offerAbove: 999,
    offerAmount: 200,
    heroImage: 'assets/images/shrimp_dish_1.png',
    topDishLabel: 'Tandoori Jhinga · ₹849',
  ),
];

/// Menu items shown when a restaurant is tapped.
class RestaurantMenuItem {
  final String name;
  final String weight;
  final double price;
  final String image;
  bool isFavorite;

  RestaurantMenuItem({
    required this.name,
    required this.weight,
    required this.price,
    required this.image,
    this.isFavorite = false,
  });
}

List<RestaurantMenuItem> getMenuForRestaurant(String restaurantId) {
  // All restaurants serve different shrimp varieties.
  return [
    RestaurantMenuItem(
      name: 'Lemon Garlic Shrimp',
      weight: '1 plate',
      price: 599,
      image: 'assets/images/shrimp_lemon_herb.png',
    ),
    RestaurantMenuItem(
      name: 'Farm Fresh Prawns',
      weight: '500g',
      price: 429,
      image: 'assets/images/shrimp_fresh_pile.png',
    ),
    RestaurantMenuItem(
      name: 'Sizzling Garlic Shrimp',
      weight: '250g',
      price: 549,
      image: 'assets/images/shrimp_dish_1.png',
    ),
    RestaurantMenuItem(
      name: 'Peppery Onion Prawns',
      weight: '300g',
      price: 489,
      image: 'assets/images/shrimp_dish_2.png',
    ),
    RestaurantMenuItem(
      name: 'Honey Chilli Shrimp',
      weight: '1 plate',
      price: 599,
      image: 'assets/images/shrimp_dish_3.png',
    ),
    RestaurantMenuItem(
      name: 'Spicy Fried Shrimp',
      weight: '400g',
      price: 529,
      image: 'assets/images/shrimp_dish_4.png',
    ),
    RestaurantMenuItem(
      name: 'Tiger Prawn Masala',
      weight: '500g',
      price: 749,
      image: 'assets/images/shrimp_tiger_trio.png',
    ),
    RestaurantMenuItem(
      name: 'Butter Garlic Prawns',
      weight: '1 plate',
      price: 669,
      image: 'assets/images/shrimp_dish_5.png',
    ),
    RestaurantMenuItem(
      name: 'Chilli Shrimp Fry',
      weight: '300g',
      price: 499,
      image: 'assets/images/shrimp_dish_6.png',
    ),
    RestaurantMenuItem(
      name: 'Shrimp Cooked Duo',
      weight: '2 plates',
      price: 899,
      image: 'assets/images/shrimp_cooked_duo.png',
    ),
  ];
}
