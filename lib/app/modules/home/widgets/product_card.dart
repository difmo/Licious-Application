import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/favorites_service.dart';
import '../view/product_details_page.dart';
import '../widgets/quantity_selector.dart';
import '../../../widgets/bounce_widget.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = CartProviderScope.of(context);

    final cartItem = cart.items.firstWhere(
      (item) => item.title == product.name,
      orElse: () => CartItem(
        id: product.id,
        title: product.name,
        unitPrice: product.price,
        subtitle: product.weight,
        image: product.image,
        category: product.category,
        quantity: 0,
      ),
    );
    final isInCart = cartItem.quantity > 0;

    return BounceWidget(
      onTap: () {
        if (!product.isShopActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This shop is currently closed.'),
              backgroundColor: Colors.black87,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Opacity(
        opacity: product.isShopActive ? 1.0 : 0.8,
        child: ColorFiltered(
          colorFilter: product.isShopActive
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Hero(
                      tag: 'product_${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          product.image,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child:
                                    Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Weight or description
                          Text(
                            product.weight,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Price & Add Area
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              // Dynamic Cart Controls
                              if (!isInCart)
                                BounceWidget(
                                  onTap: product.isShopActive ? onAdd : () {},
                                  scaleFactor: 0.9,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: product.isShopActive
                                          ? const Color(0xFF68B92E)
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                QuantitySelector(
                                  quantity: cartItem.quantity,
                                  onIncrement: product.isShopActive
                                      ? () => cart.increment(product.name)
                                      : () {},
                                  onDecrement: product.isShopActive
                                      ? () => cart.decrement(product.name)
                                      : () {},
                                  size: 32, // Compact size for grid card
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Closed Shop Badge
                if (!product.isShopActive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Badge (Offer/New)
                if (product.badgeText.isNotEmpty && product.isShopActive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Favorite Icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ProductHeart(productId: product.id),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
        begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
}

class _ProductHeart extends ConsumerStatefulWidget {
  final String productId;
  const _ProductHeart({required this.productId});

  @override
  ConsumerState<_ProductHeart> createState() => _ProductHeartState();
}

class _ProductHeartState extends ConsumerState<_ProductHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool? _localFav;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.4)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final notifier = ref.read(favoritesProvider.notifier);

    // Optimistic toggle
    final isFav = _localFav ??
        (ref.read(favoritesProvider).asData?.value.contains(widget.productId) ??
            false);

    setState(() => _localFav = !isFav);

    _controller.forward().then((_) => _controller.reverse());

    try {
      await notifier.toggle(widget.productId);
    } catch (e) {
      if (mounted) setState(() => _localFav = isFav); // Rollback on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final favsValue = ref.watch(favoritesProvider);

    // Sync local state once loaded
    favsValue.whenData((ids) {
      final fromProvider = ids.contains(widget.productId);
      if (_localFav == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _localFav = fromProvider);
        });
      }
    });

    final bool isFav = _localFav ??
        (favsValue.asData?.value.contains(widget.productId) ?? false);

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.grey.shade400,
            size: 16,
          ),
        ),
      ),
    );
  }
}
