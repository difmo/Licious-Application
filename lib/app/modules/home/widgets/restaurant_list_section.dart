import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/shop_product_model.dart';
import '../provider/shop_provider.dart';
import '../../home/view/restaurant_menu_page.dart';
import 'filter_bottom_sheet.dart';

// ── Cuisine types to cycle through for display ───────────────────────────────
const List<String> _cuisineTypes = [
  'Seafood · Coastal',
  'Seafood · Grill',
  'Seafood · Pan Asian',
  'Seafood · Kerala',
  'Seafood · Thai',
  'Seafood · Mughlai',
  'Seafood · Chinese',
  'Seafood · Continental',
  'Seafood · Goan',
  'Seafood · Fusion',
  'Seafood · Tandoor',
];

// ── Placeholder hero images (local assets as fallback) ───────────────────────
const List<String> _heroImages = [
  'assets/images/shrimp_dish_1.png',
  'assets/images/shrimp_dish_2.png',
  'assets/images/shrimp_dish_3.png',
  'assets/images/shrimp_dish_4.png',
  'assets/images/shrimp_dish_5.png',
  'assets/images/shrimp_dish_6.png',
  'assets/images/shrimp_fresh_pile.png',
  'assets/images/shrimp_lemon_herb.png',
  'assets/images/shrimp_tiger_trio.png',
  'assets/images/shrimp_cooked_duo.png',
];

// ── Offer cycling logic ───────────────────────────────────────────────────────
String _offerText(int index) {
  switch (index % 3) {
    case 0:
      return 'Flat ₹100 OFF above ₹499';
    case 1:
      return 'Flat ₹150 OFF above ₹799';
    default:
      return 'Flat ₹200 OFF above ₹999';
  }
}

int _offerAbove(int index) {
  switch (index % 3) {
    case 0:
      return 499;
    case 1:
      return 799;
    default:
      return 999;
  }
}

class RestaurantListSection extends ConsumerWidget {
  const RestaurantListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsListProvider);

    return shopsAsync.when(
      loading: () => const _ShopsLoadingState(),
      error: (err, _) => _ShopsErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(shopsListProvider),
      ),
      data: (shops) {
        if (shops.isEmpty) {
          return _ShopsEmptyState(
              onRetry: () => ref.invalidate(shopsListProvider));
        }
        return _ShopsList(shops: shops);
      },
    );
  }
}

// ── Shops List ────────────────────────────────────────────────────────────────

class _ShopsList extends StatelessWidget {
  final List<ShopModel> shops;
  const _ShopsList({required this.shops});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Text(
                'Restaurants Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                '${shops.length} places',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => FilterBottomSheet.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF68B92E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.filter_list_rounded,
                          size: 16, color: Color(0xFF68B92E)),
                      SizedBox(width: 4),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF68B92E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: shops.length,
          itemBuilder: (context, index) {
            return _ShopCard(
              shop: shops[index],
              index: index,
            );
          },
        ),
      ],
    );
  }
}

// ── Individual Shop Card ──────────────────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  final ShopModel shop;
  final int index;

  const _ShopCard({required this.shop, required this.index});

  Color get _offerColor {
    final above = _offerAbove(index);
    if (above >= 999) return const Color(0xFF7B2FF7);
    if (above >= 799) return const Color(0xFF1565C0);
    return const Color(0xFF68B92E);
  }

  String get _heroImage => _heroImages[index % _heroImages.length];
  String get _cuisine => _cuisineTypes[index % _cuisineTypes.length];

  // Generate a deterministic rating from shop ID
  double get _rating {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return 3.8 + (code % 9) * 0.1; // 3.8 – 4.6
  }

  int get _reviews {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return 600 + (code % 40) * 100; // realistic range
  }

  String get _deliveryTime {
    final mins = 50 + (index * 5) % 40;
    return '$mins–${mins + 15} mins';
  }

  double get _distance {
    final code = shop.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return ((code % 50) + 5) / 10.0; // 0.5 – 5.4 km
  }

  bool get _isFeatured => index < 3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!shop.isShopActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This shop is currently not accepting orders.'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantMenuPage(shop: shop),
          ),
        );
      },
      child: Opacity(
        opacity: shop.isShopActive ? 1.0 : 0.8,
        child: ColorFiltered(
          colorFilter: shop.isShopActive
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Hero Banner ─────────────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildHeroImage(),
                  ),
                  // Closed/Offline Overlay
                  if (!shop.isShopActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Text(
                              'CLOSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Top dish label overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shop.businessName.isNotEmpty
                            ? shop.businessName
                            : 'Fresh Shrimp · ₹499+',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Bookmark
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border,
                          size: 16, color: Colors.black54),
                    ),
                  ),
                  // Featured badge
                  if (_isFeatured)
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFFD600)),
                        ),
                        child: const Text(
                          '⭐ Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Info Row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cuisine,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF68B92E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            shop.rating > 0
                                ? shop.rating.toStringAsFixed(1)
                                : _rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatReviews(_reviews),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // ── Delivery Meta ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt,
                            size: 14, color: Color(0xFF68B92E)),
                        const SizedBox(width: 3),
                        Text(
                          shop.deliveryTime.isNotEmpty
                              ? shop.deliveryTime
                              : _deliveryTime,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                    Text('·', style: TextStyle(color: Colors.grey.shade400)),
                    Text(
                      '${_distance.toStringAsFixed(1)} km',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    Text('·', style: TextStyle(color: Colors.grey.shade400)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 3),
                        const Text(
                          'Free',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Offer Strip ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 14, color: _offerColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _offerText(index),
                        style: TextStyle(
                          fontSize: 12,
                          color: _offerColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    // Prefer banner from API, then local asset fallback
    final networkUrl = shop.image;
    if (networkUrl.length > 5) {
      return Image.network(
        networkUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localFallback(),
      );
    }
    return _localFallback();
  }

  Widget _localFallback() {
    return Image.asset(
      _heroImage,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 180,
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatReviews(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K+';
    }
    return '$count+';
  }
}

// ── Loading State ─────────────────────────────────────────────────────────────

class _ShopsLoadingState extends StatelessWidget {
  const _ShopsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Restaurants Near You',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        ...List.generate(3, (i) => const _ShopShimmerCard()),
      ],
    );
  }
}

class _ShopShimmerCard extends StatefulWidget {
  const _ShopShimmerCard();

  @override
  State<_ShopShimmerCard> createState() => _ShopShimmerCardState();
}

class _ShopShimmerCardState extends State<_ShopShimmerCard>
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: _anim.value),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _anim.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _anim.value * 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: _anim.value * 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
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

// ── Error State ───────────────────────────────────────────────────────────────

class _ShopsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ShopsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Could not load restaurants',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check connection and try again.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF68B92E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _ShopsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ShopsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No restaurants found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back later for nearby restaurants.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF68B92E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
