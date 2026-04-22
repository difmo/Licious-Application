import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/services/shop_service.dart';
import '../provider/filter_provider.dart';
import '../../../widgets/modern_filter_bottom_sheet.dart';

class FilteredProductsPage extends ConsumerWidget {
  const FilteredProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Filtered Products',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF68B92E)),
            onPressed: () => ModernFilterBottomSheet.show(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(shopServiceProvider).getFilteredProducts(
          minPrice: filter.minPrice,
          maxPrice: filter.maxPrice,
          minRating: filter.minRating,
          hasDiscount: filter.hasDiscount,
          freeShipping: filter.freeShipping,
          sameDayDelivery: filter.sameDayDelivery,
          category: filter.category,
          sortBy: filter.sortBy,
          search: filter.search,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final products = snapshot.data?['products'] as List<ShopProduct>? ?? [];
          final total = snapshot.data?['total'] as int? ?? 0;
          
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No products match your filters', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.read(productFilterProvider.notifier).reset(),
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Found $total results',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _FilterProductCard(product: product);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterProductCard extends StatelessWidget {
  final ShopProduct product;
  const _FilterProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Since we don't have the full shop model here, we navigate to a placeholder or details page
        // For now, let's just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${product.name} from retailer ${product.retailerId}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  product.primaryImage,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.set_meal, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      if (product.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
