import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/food_models.dart';

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  _HeaderDelegate({required this.expandedHeight});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = (1 - (shrinkOffset / expandedHeight)).clamp(0.0, 1.0);
    
    return OverflowBox(
      maxWidth: MediaQuery.of(context).size.width + 50, // Massive bleed to bypass any parent constraints
      minWidth: MediaQuery.of(context).size.width + 50,
      alignment: Alignment.center,
      child: Transform.scale(
        scaleX: 1.1, // Increased scale to push content well beyond the edges
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/image copy 10.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: opacity,
                child: const Text(
                  'My Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 15)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;
  @override
  double get minExtent => kToolbarHeight + 20;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  void _reorder(BuildContext context, String restaurantName) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reordering from $restaurantName...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF114F3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final orders = cart.orders;

    // Use MediaQuery.removePadding to ensure NO horizontal padding is injected from parent builds
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      removeTop: true,
      child: Material(
        color: Colors.white,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(expandedHeight: 200.0),
            ),
          if (orders.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No orders yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      onReorder: () => _reorder(context, order.restaurantName),
                    );
                  },
                  childCount: orders.length,
                ),
<<<<<<< HEAD
                decoration: BoxDecoration(
                  color: order.status.toLowerCase() == 'delivered'
                      ? const Color(0xFFE8F5E9)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: order.status.toLowerCase() == 'delivered'
                        ? const Color(0xFF68B92E)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date and Order ID
          Row(
            children: [
              Text(
                'Order ID: ${order.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Text(
                order.date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Recurring Badge and Delivery Info
          if (order.isSubscription) 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF68B92E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.autorenew_rounded, size: 14, color: Color(0xFF68B92E)),
                        SizedBox(width: 4),
                        Text(
                          'RECURRING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF68B92E),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order.deliveryDate != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Next: ${order.deliveryDate}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Items List
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 4, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Total and Reorder Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subtotal: ₹240.00', // Mock breakdown
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Text(
                    'Wallet Applied: -₹240.00',
                    style: TextStyle(fontSize: 10, color: Color(0xFF68B92E)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Final Bill',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF68B92E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reorder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
=======
              ),
            ),
          // Extra padding for bottom navigation
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
>>>>>>> 0d6934473b23ad73b413e0ace1dfe03bdbcf2572
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final UserOrder order;
  final VoidCallback onReorder;

  const _OrderCard({
    required this.order,
    required this.onReorder,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Map restaurant names to assets for visual consistency in the demo
  String _getRestaurantImage(String name) {
    if (name.contains('Shrimp')) return 'assets/images/shrimp_tiger_trio.png';
    if (name.contains('Palat') || name.contains('Burger')) return 'assets/images/shrimp_cooked_duo.png';
    return 'assets/images/shrimp_dish_1.png';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDelivered = order.status.toLowerCase() == 'delivered';

    return GestureDetector(
      onDoubleTap: () {
        widget.onReorder();
        _controller.forward().then((_) => _controller.reverse());
      },
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3436).withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: Image.asset(
                  _getRestaurantImage(order.restaurantName),
                  width: 120,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.restaurantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2D3436),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDelivered ? const Color(0xFFC8E6C9) : const Color(0xFFFFD8A8),
                              ),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: isDelivered ? const Color(0xFF2E7D32) : const Color(0xFFE67E22),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.items.join(', '),
                        style: const TextStyle(
                          color: Color(0xFF636E72),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Bill',
                                style: TextStyle(
                                  color: Color(0xFF636E72),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              widget.onReorder();
                              _controller.forward().then((_) => _controller.reverse());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Reorder',
                                style: TextStyle(
                                  color: Color(0xFF2D3436),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
