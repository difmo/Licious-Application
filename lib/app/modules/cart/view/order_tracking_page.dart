import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/services/order_service.dart';
import '../../../routes/app_routes.dart';

final orderDetailsProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, id) {
  return ref.read(orderServiceProvider).getOrderDetails(id);
});

class OrderTrackingPage extends ConsumerWidget {
  final String? orderId;
  const OrderTrackingPage({super.key, this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id =
        orderId ?? (ModalRoute.of(context)?.settings.arguments as String?);

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: Text('No Order ID provided')),
      );
    }

    final orderAsync = ref.watch(orderDetailsProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null)
            return const Center(child: Text('Order not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfoCard(order),
                const SizedBox(height: 24),
                const Text(
                  'Order Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTrackingStepper(order),
                const SizedBox(height: 24),
                _buildDeliveryDetails(order),
                const SizedBox(height: 32),
                if (order['status'] == 'Out for Delivery') ...[
                  _buildLiveTrackButton(context, id),
                  const SizedBox(height: 16),
                ],
                _buildGoHomeButton(context),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF68B92E))),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> order) {
    final id = order['_id']?.toString() ?? '';
    final shortId =
        id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
    final status = order['status']?.toString() ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: #SH-$shortId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'Delivered'
                        ? 'Order Delivered'
                        : 'Arriving in 25-30 mins',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBFFD7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: Color(0xFF68B92E),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F4F8)),
          const SizedBox(height: 16),
          _buildItemsSummary(order),
        ],
      ),
    );
  }

  Widget _buildItemsSummary(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox();

    return Column(
      children: items.map((item) {
        final product = item['product'];
        final name =
            product is Map ? product['name']?.toString() ?? 'Item' : 'Item';
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final qty = item['quantity'] ?? 1;
        final images =
            product is Map ? product['images'] as List<dynamic>? : null;
        final imageUrl =
            images != null && images.isNotEmpty ? images.first.toString() : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.shopping_bag_outlined,
                        color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Qty $qty',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${(price * qty).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF68B92E),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrackingStepper(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'Pending';
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final timeFormat = DateFormat('h:mm a');

    bool isPlaced = true;
    bool isProcessing = [
      'Processing',
      'Packed',
      'Out for Delivery',
      'Delivered'
    ].contains(status);
    bool isPacked =
        ['Packed', 'Out for Delivery', 'Delivered'].contains(status);
    bool isOut = ['Out for Delivery', 'Delivered'].contains(status);
    bool isDelivered = status == 'Delivered';

    return Column(
      children: [
        _buildStepItem(
          'Order Placed',
          timeFormat.format(createdAt),
          'Your order has been received.',
          icon: Icons.receipt_long_rounded,
          isCompleted: isPlaced,
          isFirst: true,
          isActive: status == 'Pending',
        ),
        _buildStepItem(
          'Processing',
          timeFormat.format(createdAt.add(const Duration(minutes: 5))),
          'Our experts are picking the freshest catch.',
          icon: Icons.restaurant_rounded,
          isCompleted: isProcessing,
          isActive: status == 'Processing',
        ),
        _buildStepItem(
          'Packed & Ready',
          timeFormat.format(createdAt.add(const Duration(minutes: 15))),
          'Waiting for the delivery partner.',
          icon: Icons.inventory_2_rounded,
          isCompleted: isPacked,
          isActive: status == 'Packed',
        ),
        _buildStepItem(
          'Out for Delivery',
          timeFormat.format(createdAt.add(const Duration(minutes: 25))),
          isDelivered ? 'Rider was on the way!' : 'Your order is on the way!',
          icon: Icons.delivery_dining_rounded,
          isCompleted: isOut,
          isLast: true,
          isActive: status == 'Out for Delivery',
        ),
      ],
    );
  }

  Widget _buildStepItem(
    String title,
    String time,
    String description, {
    required IconData icon,
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
    bool isActive = false,
  }) {
    final statusColor = isCompleted || isActive
        ? const Color(0xFF68B92E)
        : Colors.grey.shade400;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF68B92E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF68B92E).withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : statusColor,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? const Color(0xFF68B92E)
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCompleted || isActive
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isCompleted || isActive
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetails(Map<String, dynamic> order) {
    final address = order['deliveryAddress'];
    String addressStr = 'No address details';
    if (address is Map) {
      addressStr =
          '${address['street'] ?? ''}, ${address['city'] ?? ''}'.trim();
      if (addressStr == ',') addressStr = 'Default Address';
    } else if (address != null) {
      addressStr = address.toString();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF68B92E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  addressStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackButton(BuildContext context, String orderId) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to TrackOrderPage (the one with Google Maps)
          Navigator.pushNamed(context, AppRoutes.trackOrder,
              arguments: orderId);
        },
        icon: const Icon(Icons.map_rounded),
        label: const Text(
          'Track Live on Map',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF68B92E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF68B92E).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildGoHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF439462).withValues(alpha: 0.1),
          foregroundColor: const Color(0xFF439462),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Back to Home',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
