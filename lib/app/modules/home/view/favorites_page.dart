import 'package:flutter/material.dart';

import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../controller/main_controller.dart';
import '../widgets/product_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = CartProviderScope.of(context);
    final favorites = provider.recommendedProducts
        .where((p) => provider.isFavorite(p.id))
        .toList();

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
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return ProductCard(
                  product: product,
                  onAdd: () {
                    provider.addToCart(CartItem.fromProduct(product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onFavorite: () {
                    provider.toggleFavorite(product.id);
                  },
                );
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
}
