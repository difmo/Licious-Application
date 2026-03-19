import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/db_service.dart';
import '../../../data/services/favorites_service.dart';
import '../provider/shop_provider.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/quantity_selector.dart';
import 'package:licius_application/app/routes/app_routes.dart';

class RestaurantMenuPage extends ConsumerWidget {
  final ShopModel shop;
  const RestaurantMenuPage({super.key, required this.shop});

  // Deterministic display metadata (same logic as the card)
  double get _rating {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return 3.8 + (code % 9) * 0.1;
  }

  String get _deliveryTime {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    final mins = 50 + (code % 40);
    return '$mins–${mins + 15} mins';
  }

  double get _distance {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return ((code % 50) + 5) / 10.0;
  }

  String get _heroImage {
    final images = [
      'assets/images/shrimp_dish_1.png',
      'assets/images/shrimp_dish_2.png',
      'assets/images/shrimp_dish_3.png',
      'assets/images/shrimp_lemon_herb.png',
      'assets/images/shrimp_tiger_trio.png',
      'assets/images/shrimp_cooked_duo.png',
    ];
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return images[code % images.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsListProvider);
    final currentShop = shopsAsync.maybeWhen(
      data: (list) =>
          list.firstWhere((s) => s.id == shop.id, orElse: () => shop),
      orElse: () => shop,
    );
    final productsAsync = ref.watch(shopProductsProvider(currentShop.id));
    final cart = CartProviderScope.of(context);
    final isShopActive = currentShop.isShopActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          ColorFiltered(
            colorFilter: isShopActive
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            child: Opacity(
              opacity: isShopActive ? 1.0 : 0.8,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Hero App Bar ──────────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black87, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: const Icon(Icons.bookmark_border,
                              color: Colors.black87, size: 20),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeroBanner(currentShop),
                    ),
                  ),

                  // ── Restaurant Info Card ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.deliveryTime.isNotEmpty
                                          ? shop.deliveryTime
                                          : _deliveryTime,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    if (shop.location.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        shop.location,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF68B92E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      shop.rating > 0
                                          ? shop.rating.toStringAsFixed(1)
                                          : _rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Delivery meta chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MetaChip(
                                icon: Icons.bolt,
                                label: _deliveryTime,
                                iconColor: const Color(0xFF68B92E),
                              ),
                              _MetaChip(
                                icon: Icons.location_on_outlined,
                                label: '${_distance.toStringAsFixed(1)} km',
                                iconColor: Colors.grey,
                              ),
                              _MetaChip(
                                icon: Icons.delivery_dining_outlined,
                                label: 'Free delivery',
                                iconColor: Colors.grey,
                              ),
                            ],
                          ),
                          if (!isShopActive) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This restaurant is currently offline and not accepting orders.',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            // Offer banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBFFD7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer,
                                      size: 14, color: Color(0xFF439462)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Flat ₹100 OFF above ₹499',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF439462),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Products Section Header ────────────────────────────────────
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'SHRIMP VARIETIES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  // ── Products Grid ─────────────────────────────────────────────
                  productsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: _ProductsLoadingGrid(),
                    ),
                    error: (err, _) => SliverToBoxAdapter(
                      child: _ProductsErrorState(
                        message: err.toString(),
                        onRetry: () =>
                            ref.invalidate(shopProductsProvider(shop.id)),
                      ),
                    ),
                    data: (products) {
                      if (products.isEmpty) {
                        return const SliverToBoxAdapter(
                            child: _ProductsEmptyState());
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = products[index];
                              return _ProductCard(
                                product: product,
                                index: index,
                                shopId: currentShop.id,
                                shopName: currentShop.name,
                                isShopActive: isShopActive,
                              );
                            },
                            childCount: products.length,
                          ),
                        ),
                      );
                    },
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
            ),
          ),

          // ── Floating Back Button (Above Grayscale) ────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          if (cart.itemCount > 0 && isShopActive)
            Positioned(
              bottom:
                  30, // Positioned near bottom since this page doesn't have a persistent bottom bar like MainPage
              left: 0,
              right: 0,
              child: CartSummaryBar(
                cart: cart,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.cart);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ShopModel currentShop) {
    final networkUrl = currentShop.image;
    if (networkUrl.length > 5) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localHero(),
      );
    }
    return _localHero();
  }

  Widget _localHero() {
    return Image.asset(
      _heroImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.restaurant, size: 64, color: Colors.grey)),
      ),
    );
  }
}

// ── Product Card (API-driven) ─────────────────────────────────────────────────

class _ProductCard extends ConsumerStatefulWidget {
  final ShopProduct product;
  final int index;
  final String shopId;
  final String shopName;
  final bool isShopActive;

  const _ProductCard({
    required this.product,
    required this.index,
    required this.shopId,
    required this.shopName,
    required this.isShopActive,
  });

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final p = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product Image ─────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: p.primaryImage.isNotEmpty
                    ? Image.network(
                        p.primaryImage,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // Favorite button — wired to backend
              Positioned(
                top: 6,
                right: 6,
                child: _FavoriteHeart(productId: p.id),
              ),
              // Out of stock badge
              if (!p.isAvailable)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Product Info ──────────────────────────────────────────────
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
                const SizedBox(height: 2),
                if (p.category != null)
                  Text(
                    p.category!.name,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (p.description.isNotEmpty)
                  Text(
                    p.description,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const Spacer(),

          // ── Price + Add to Cart ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                // Dynamic Cart Controls
                if (p.isAvailable)
                  _buildCartControls(context, cart, p, widget.shopName)
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: (60 * widget.index).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _buildCartControls(
      BuildContext context, CartProvider cart, ShopProduct p, String shopName) {
    final cartItem = cart.items.firstWhere(
      (item) => item.id == p.id,
      orElse: () => CartItem(
        id: p.id,
        title: p.name,
        unitPrice: p.price,
        subtitle: p.category?.name ?? 'Shrimp',
        image: p.primaryImage,
        category: 'restaurant',
        shopId: widget.shopId,
        shopName: shopName,
        quantity: 0,
      ),
    );

    if (!widget.isShopActive) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.block, color: Colors.grey, size: 18),
      );
    }

    if (cartItem.quantity == 0) {
      return GestureDetector(
        onTap: () {
          if (cart.isSameShop(widget.shopId)) {
            cart.addToCart(CartItem(
              id: p.id,
              title: p.name,
              unitPrice: p.price,
              subtitle: p.category?.name ?? 'Shrimp',
              image: p.primaryImage,
              category: 'restaurant',
              shopId: widget.shopId,
              shopName: shopName,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${p.name} added to cart!'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF439462),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else {
            _showReplaceCartDialog(context, cart, p, shopName);
          }
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF68B92E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      );
    }

    return QuantitySelector(
      quantity: cartItem.quantity,
      onIncrement: () => cart.increment(p.name),
      onDecrement: () => cart.decrement(p.name),
      size: 32, // Compact size for grid card
    );
  }

  void _showReplaceCartDialog(BuildContext context, CartProvider cart,
      ShopProduct p, String newShopName) {
    final oldShopName = cart.cartShopName ?? 'another shop';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Replace cart item?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'Your cart contains dishes from $oldShopName. Do you want to discard the selection and add dishes from $newShopName?',
          style:
              const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFFFF1F0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(
                        color: Color(0xFFFC5A44), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    cart.clearCart();
                    cart.addToCart(CartItem(
                      id: p.id,
                      title: p.name,
                      unitPrice: p.price,
                      subtitle: p.category?.name ?? 'Shrimp',
                      image: p.primaryImage,
                      category: 'restaurant',
                      shopId: widget.shopId,
                      shopName: newShopName,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Cart replaced with items from $newShopName'),
                        backgroundColor: const Color(0xFF439462),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFFC5A44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Replace',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 110,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.set_meal_outlined, size: 36, color: Colors.grey),
      ),
    );
  }
}

// ── Favorite Heart Button ─────────────────────────────────────────────────────

/// Standalone heart-toggle widget.
///  - Seeds its local `_isFav` from [favoritesProvider] once loaded.
///  - Responds to taps IMMEDIATELY (no wait for provider loading).
///  - Calls [FavoritesNotifier.toggle] which does: optimistic update → API → invalidate products list.
class _FavoriteHeart extends ConsumerStatefulWidget {
  final String productId;
  const _FavoriteHeart({required this.productId});

  @override
  ConsumerState<_FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends ConsumerState<_FavoriteHeart>
    with SingleTickerProviderStateMixin {
  bool? _localFav; // null = not yet seeded
  late AnimationController _bounce;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_bounce);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Animate the heart
    await _bounce.forward();
    _bounce.reverse();

    // Flip local state immediately (instant visual feedback)
    setState(() => _localFav = !(_localFav ?? false));

    // Delegate the actual API call + provider update
    await ref.read(favoritesProvider.notifier).toggle(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    // Sync local state from provider once it's loaded
    final favsValue = ref.watch(favoritesProvider);
    favsValue.whenData((ids) {
      final fromProvider = ids.contains(widget.productId);
      if (_localFav == null) {
        // First time data is ready — seed local state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _localFav = fromProvider);
        });
      }
    });

    // Use local state if seeded, else fall back to provider (or false while loading)
    final bool isFav = _localFav ??
        (favsValue.asData?.value.contains(widget.productId) ?? false);

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFav
                ? Colors.red.shade50.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            size: 15,
            color: isFav ? Colors.red : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ── Products Loading Grid ─────────────────────────────────────────────────────

class _ProductsLoadingGrid extends StatelessWidget {
  const _ProductsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const _ProductShimmerCard(),
      ),
    );
  }
}

class _ProductShimmerCard extends StatefulWidget {
  const _ProductShimmerCard();

  @override
  State<_ProductShimmerCard> createState() => _ProductShimmerCardState();
}

class _ProductShimmerCardState extends State<_ProductShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: _anim.value),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey.withValues(alpha: _anim.value)),
                  const SizedBox(height: 6),
                  Container(
                      height: 10,
                      width: 70,
                      color: Colors.grey.withValues(alpha: _anim.value * 0.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products Error/Empty States ───────────────────────────────────────────────

class _ProductsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProductsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Failed to load products',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Login required to view menu.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
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
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.no_meals_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No products available',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 6),
            Text('This restaurant has no products yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Meta Chip Helper ──────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
