import 'package:flutter/material.dart';

import '../../../data/services/db_service.dart';
import '../../../data/models/food_models.dart';
import '../controller/main_controller.dart';
import 'restaurant_menu_page.dart'; // I think this is the right path for menu page
import '../../../data/models/shop_product_model.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = CartProviderScope.of(context);
    final favorites = provider.favRestaurants;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? _buildEmptyState(context)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return _buildFavoriteItem(context, provider, favorites[index], index);
              },
              onReorder: (oldIndex, newIndex) {
                provider.reorderFavorites(oldIndex, newIndex);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 80,
              color: const Color(0xFF68B92E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nothing in Favorites',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore your favorite food and\nsave them for later!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                MainControllerScope.of(context).changePage(0); // Home tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF439462),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Go Shopping',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
    BuildContext context,
    CartProvider provider,
    Restaurant restaurant,
    int index,
  ) {
    return Container(
      key: ValueKey('fav_${restaurant.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(restaurant.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        onDismissed: (direction) {
          provider.toggleFavorite(restaurant.id);
        },
        child: GestureDetector(
          onTap: () {
            // Convert Restaurant to ShopModel if they are different, or pass as is if compatible
            // For now, navigating to menu page
             final shop = ShopModel(
              id: restaurant.id,
              name: restaurant.name,
              image: restaurant.image,
              businessName: restaurant.name,
              rating: restaurant.rating,
              deliveryTime: restaurant.deliveryTime,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantMenuPage(shop: shop),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.asset(
                        restaurant.image,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => provider.toggleFavorite(restaurant.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, color: Color(0xFF68B92E), size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.categories.join(', '),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
