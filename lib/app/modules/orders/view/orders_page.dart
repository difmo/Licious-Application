import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/socket_service.dart';
import '../../auth/provider/auth_provider.dart';

// Local provider removed, using shared provider from order_service.dart


class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  _HeaderDelegate({required this.expandedHeight});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity =
        (1 - (shrinkOffset / expandedHeight)).clamp(0.0, 1.0);

    return OverflowBox(
      maxWidth: MediaQuery.of(context).size.width + 50,
      minWidth: MediaQuery.of(context).size.width + 50,
      alignment: Alignment.center,
      child: Transform.scale(
        scaleX: 1.1,
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
  }

  void _setupSocket() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final socket = ref.read(socketServiceProvider);
    socket.joinUserRoom(user.id);
    socket.onRiderAssigned((data) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showRiderAssignedPopup(data);
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).offEvent('riderAssigned');
    super.dispose();
  }

  void _showRiderAssignedPopup(dynamic data) {
    final riderName = data?['rider']?['name'] ?? 'Your Rider';
    final riderPhone = data?['rider']?['phone'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF114F3B).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining,
                    size: 48, color: Color(0xFF114F3B)),
              ),
              const SizedBox(height: 20),
              const Text('🎉 Rider Assigned!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$riderName is on the way to pick up your order.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              if (riderPhone.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Color(0xFF114F3B), size: 18),
                    const SizedBox(width: 6),
                    Text(riderPhone,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF114F3B)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('OK',
                          style: TextStyle(color: Color(0xFF114F3B))),
                    ),
                  ),
                  if (riderPhone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Launch phone call
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF114F3B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.call,
                            size: 16, color: Colors.white),
                        label: const Text('Call',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Refresh orders list
    ref.invalidate(myOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);

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
            // Refresh action
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF114F3B)),
                    onPressed: () => ref.invalidate(myOrdersProvider),
                  ),
                ),
              ),
            ),
            ordersAsync.when(
              data: (orders) => orders.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('No orders yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _LiveOrderCard(order: orders[index]),
                          childCount: orders.length,
                        ),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF114F3B))),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _LiveOrderCard({required this.order});

  @override
  State<_LiveOrderCard> createState() => _LiveOrderCardState();
}

class _LiveOrderCardState extends State<_LiveOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return 'Order';
    final p = items.first['product'];
    return (p is Map && p['name'] != null) ? p['name'].toString() : 'Order';
  }

  String get _description {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    return items.map((i) {
      final p = i['product'];
      final name = p is Map ? p['name']?.toString() ?? 'Item' : 'Item';
      return '${i['quantity']}x $name';
    }).join(', ');
  }

  double get _total {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    return items.fold(0.0, (sum, i) {
      final price = (i['price'] as num?)?.toDouble() ?? 0;
      final qty = (i['quantity'] as num?)?.toDouble() ?? 1;
      return sum + price * qty;
    });
  }

  String get _status => widget.order['status']?.toString() ?? 'Pending';

  bool get _isDelivered => _status.toLowerCase() == 'delivered';

  Color get _statusColor {
    switch (_status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return Colors.red;
      case 'out for delivery':
        return Colors.blue;
      default:
        return const Color(0xFFE67E22);
    }
  }

  Color get _statusBg {
    switch (_status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF4E5);
    }
  }

  String get _imageUrl {
    final items = widget.order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return '';
    final p = items.first['product'];
    if (p is Map) {
      final imgs = p['images'] as List<dynamic>?;
      return (imgs != null && imgs.isNotEmpty) ? imgs.first.toString() : '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to cart for reorder!'),
          backgroundColor: Color(0xFF114F3B),
        ));
        _controller.forward().then((_) => _controller.reverse());
      },
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
                color: const Color(0xFF2D3436).withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                child: _imageUrl.isNotEmpty
                    ? Image.network(_imageUrl,
                        width: 120,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder)
                    : _placeholder,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3436)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _status,
                              style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _description,
                        style: const TextStyle(
                            color: Color(0xFF636E72),
                            fontSize: 12,
                            height: 1.3),
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
                              const Text('Total Bill',
                                  style: TextStyle(
                                      color: Color(0xFF636E72), fontSize: 10)),
                              Text(
                                '₹${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2D3436)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFE67E22), width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isDelivered ? 'Reorder' : 'Track',
                              style: const TextStyle(
                                  color: Color(0xFF2D3436),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
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

  Widget get _placeholder => Container(
        width: 120,
        height: 150,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.set_meal, size: 40, color: Color(0xFF114F3B)),
      );
}
