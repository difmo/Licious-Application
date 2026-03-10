import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/order_service.dart';
import '../../orders/view/order_tracking_page.dart';

// Live order data provider
final myOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(orderServiceProvider).getMyOrders();
});

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 60.0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 14),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF114F3B)),
                onPressed: () => ref.invalidate(myOrdersProvider),
              ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'My Orders',
                style: TextStyle(
                  color: Color(0xFF114F3B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          ordersAsync.when(
            data: (orders) => orders.isEmpty
                ? const SliverFillRemaining(child: _EmptyOrdersView())
                : SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _OrderCard(order: orders[index]),
                        childCount: orders.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF114F3B)),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Failed to load orders: $err')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined,
            size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No orders yet',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        const Text('Your orders will appear here after you place one.',
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
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

  String _orderTitle() {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return 'Order';
    final first = items.first;
    final product = first['product'];
    if (product is Map) return product['name']?.toString() ?? 'Order';
    return 'Order';
  }

  String _orderDescription() {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    return items.map((i) {
      final product = i['product'];
      final name =
          product is Map ? product['name']?.toString() ?? 'Item' : 'Item';
      final qty = i['quantity']?.toString() ?? '1';
      return '${qty}x $name';
    }).join(', ');
  }

  double _totalPrice() {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    double total = 0;
    for (final item in items) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      total += price * qty;
    }
    return total;
  }

  String _orderStatus() => widget.order['status']?.toString() ?? 'Pending';

  bool _isDelivered() => _orderStatus().toLowerCase() == 'delivered';

  Color _statusColor() {
    switch (_orderStatus().toLowerCase()) {
      case 'delivered':
        return const Color(0xFFE67E22);
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF114F3B);
    }
  }

  String _imageUrl() {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return '';
    final product = items.first['product'];
    if (product is Map) {
      final images = product['images'] as List<dynamic>? ?? [];
      return images.isNotEmpty ? images.first.toString() : '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3436).withOpacity(0.05),
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
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 130,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
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
                              _orderTitle(),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _statusColor().withOpacity(0.4)),
                            ),
                            child: Text(
                              _orderStatus(),
                              style: TextStyle(
                                color: _statusColor(),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _orderDescription(),
                        style: const TextStyle(
                          color: Color(0xFF636E72),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
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
                                    color: Color(0xFF636E72), fontSize: 10),
                              ),
                              Text(
                                '₹${_totalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                            ],
                          ),
                          if (!_isDelivered())
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderTrackingPage(order: widget.order),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFE67E22),
                                      width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Track Order',
                                  style: TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart for reorder!'),
                                    backgroundColor: Color(0xFF114F3B),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFE67E22),
                                      width: 1.5),
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

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 160,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.set_meal, size: 48, color: Color(0xFF114F3B)),
    );
  }
}
