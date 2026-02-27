import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../../home/widgets/product_card.dart';

class CategoryItemsPage extends StatelessWidget {
  final String categoryName;

  const CategoryItemsPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final products = cart.getProductsByCategory(categoryName);

    return Scaffold(
      backgroundColor: const Color(0xFFEBFFD7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBFFD7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
      ),
      body: products.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductItem(context, cart, product);
              },
            ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    CartProvider cart,
    dynamic product,
  ) {
    return ProductCard(
      product: product,
      onAdd: () => cart.addToCart(CartItem.fromProduct(product)),
      onFavorite: () => cart.toggleFavorite(product.id),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are updating our stock.\nCheck back soon!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
