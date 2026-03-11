import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/services/favorites_service.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../controller/main_controller.dart';
import '../widgets/quantity_selector.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(favoriteProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Favorite Products',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF68B92E)),
            onPressed: () => ref.invalidate(favoriteProductsProvider),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF68B92E)),
        ),
        error: (err, _) => _buildError(context, ref, err),
        data: (products) => products.isEmpty
            ? _buildEmptyState(context)
            : _buildGrid(context, ref, products),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, List<ShopProduct> products) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _FavProductCard(product: products[index]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              size: 72,
              color: Color(0xFF68B92E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nothing in Favorites yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the ❤️ on any product\nto save it here!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => MainControllerScope.of(context).changePage(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF439462),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 0,
            ),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Explore Products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Could not load favorites',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(err.toString(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(favoriteProductsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF68B92E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Favorite Product Card ─────────────────────────────────────────────────────

class _FavProductCard extends ConsumerWidget {
  final ShopProduct product;
  const _FavProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = CartProviderScope.of(context);
    final p = product;
    final isFav = ref.watch(favoritesProvider).maybeWhen(
          data: (ids) => ids.contains(p.id),
          orElse: () => true,
        );

    final cartItem = cart.items.firstWhere(
      (item) => item.id == p.id,
      orElse: () => CartItem(
          id: p.id,
          title: p.name,
          unitPrice: p.price,
          subtitle: p.category?.name ?? '',
          image: p.primaryImage,
          category: 'restaurant',
          quantity: 0),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + heart button ─────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: p.primaryImage.isNotEmpty
                    ? Image.network(
                        p.primaryImage,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              // Live heart toggle (unfav removes from list)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(favoritesProvider.notifier).toggle(p.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.red.shade50
                          : Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isFav),
                        color: isFav ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Info ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (p.category != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.category!.name,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // ── Price + cart ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (cartItem.quantity == 0)
                  GestureDetector(
                    onTap: () {
                      cart.addToCart(CartItem(
                        id: p.id,
                        title: p.name,
                        unitPrice: p.price,
                        subtitle: p.category?.name ?? 'Shrimp',
                        image: p.primaryImage,
                        category: 'restaurant',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${p.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF439462),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF68B92E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  )
                else
                  QuantitySelector(
                    quantity: cartItem.quantity,
                    onIncrement: () => cart.increment(p.name),
                    onDecrement: () => cart.decrement(p.name),
                    size: 30,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 120,
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.set_meal_outlined, size: 36, color: Colors.grey),
        ),
      );
}
