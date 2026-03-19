import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/order_service.dart';
import 'track_order_page.dart';

class ActiveOrdersPage extends ConsumerStatefulWidget {
  const ActiveOrdersPage({super.key});

  @override
  ConsumerState<ActiveOrdersPage> createState() => _ActiveOrdersPageState();
}

class _ActiveOrdersPageState extends ConsumerState<ActiveOrdersPage> {
  @override
  void initState() {
    super.initState();
    // The provider now handles real-time updates via socket1
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4EC),
      appBar: AppBar(
        title: const Text('Active Orders',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF114F3B))),
        backgroundColor: const Color(0xFFF0F4EC),
        foregroundColor: const Color(0xFF114F3B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF114F3B)),
            onPressed: () => ref.invalidate(activeOrdersProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: activeOrdersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            color: const Color(0xFF114F3B),
            onRefresh: () async =>
                ref.read(activeOrdersProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _ActiveOrderCard(order: orders[index]),
            ),
          );
        },
        loading: () => _buildLoading(),
        error: (err, _) => _buildError(err),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const _ShimmerBox(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 56, color: Color(0xFF68B92E)),
          ),
          const SizedBox(height: 24),
          const Text('No Active Orders',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF114F3B))),
          const SizedBox(height: 8),
          Text('Place an order and track it live here!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Order Something'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF114F3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Could not load orders',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(err.toString(),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(activeOrdersProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF114F3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────────────────────

class _ActiveOrderCard extends StatelessWidget {
  final dynamic order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final String rawId =
        (order['orderId'] ?? order['_id'] ?? order['id'] ?? '').toString();
    final String orderId = rawId.length > 8
        ? rawId.substring(rawId.length - 8).toUpperCase()
        : rawId.toUpperCase();
    final String status = order['status']?.toString() ?? 'Pending';
    final double total =
        (order['totalAmount'] ?? order['grandTotal'] ?? order['total'] ?? 0)
            .toDouble();

    // Items
    final items = order['items'] as List? ?? [];
    final String itemsSummary = items.isNotEmpty
        ? items.map((i) => i['name'] ?? i['productName'] ?? 'Item').join(', ')
        : 'See details';

    // Rider info
    final rider = order['rider'] ?? order['riderId'];
    final String riderName =
        rider is Map ? (rider['fullName'] ?? rider['name'] ?? '') : '';
    final String riderPhone =
        rider is Map ? (rider['phoneNumber'] ?? rider['phone'] ?? '') : '';

    // Delivery address
    final deliveryAddressMap = order['deliveryAddress'];
    final String deliveryAddress = deliveryAddressMap is Map
        ? (deliveryAddressMap['fullAddress'] ??
            deliveryAddressMap['address'] ??
            'Your delivery address')
        : (order['address']?.toString() ?? 'Your delivery address');

    // Status color
    final statusInfo = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrackOrderPage(
                orderId: (order['orderId'] ?? order['_id'] ?? order['id'] ?? '')
                    .toString(),
                status: status,
                deliveryAddress: deliveryAddressMap is Map
                    ? Map<String, dynamic>.from(deliveryAddressMap)
                    : null,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top colored header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: statusInfo['bg'] as Color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #$orderId',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // ── Items summary ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.set_meal_outlined,
                      size: 18, color: Color(0xFF68B92E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(itemsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xFF1A1A1A))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Location ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF114F3B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(deliveryAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Rider chip (if assigned) ─────────────────────────────────────
            if (riderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF114F3B),
                        child: Text(
                          riderName.isNotEmpty
                              ? riderName[0].toUpperCase()
                              : 'R',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(riderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Your delivery partner',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                      if (riderPhone.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // open dialer
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF114F3B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.call,
                                color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Footer ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Text('₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF114F3B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'pickedup':
      case 'picked_up':
        return 'PICKED UP';
      case 'ontheway':
      case 'out_for_delivery':
      case 'out for delivery':
        return 'OUT FOR DELIVERY';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
    }
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'bg': const Color(0xFFF59E0B), 'text': Colors.white};
      case 'accepted':
        return {'bg': const Color(0xFF3B82F6), 'text': Colors.white};
      case 'pickedup':
      case 'picked_up':
        return {'bg': const Color(0xFF8B5CF6), 'text': Colors.white};
      case 'ontheway':
      case 'out_for_delivery':
      case 'out for delivery':
        return {'bg': const Color(0xFFEF4444), 'text': Colors.white};
      default:
        return {'bg': const Color(0xFF114F3B), 'text': Colors.white};
    }
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7)
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
          color: Colors.grey.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
