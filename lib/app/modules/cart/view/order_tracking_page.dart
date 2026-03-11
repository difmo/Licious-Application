import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/socket_service.dart';

class OrderTrackingPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String _currentStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    _connectSocket();
  }

  Future<void> _fetchOrder() async {
    final service = ref.read(orderServiceProvider);
    final data = await service.getOrderDetails(widget.orderId);
    if (mounted) {
      setState(() {
        _orderData = data;
        _currentStatus =
            data?['orderStatus'] ?? data?['paymentStatus'] ?? 'Pending';
        _isLoading = false;
      });
    }
  }

  void _connectSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.joinOrderRoom(widget.orderId);
    socket.onOrderUpdate((data) {
      if (mounted && data['orderId'] == widget.orderId) {
        setState(() {
          _currentStatus = data['status'] ?? _currentStatus;
          if (data['data'] != null && _orderData != null) {
            _orderData = {..._orderData!, ...data['data']};
          }
        });
      }
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).leaveOrderRoom(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF68B92E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfoCard(),
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
                  _buildTrackingStepper(),
                  const SizedBox(height: 24),
                  _buildDeliveryDetails(),
                  const SizedBox(height: 32),
                  _buildGoHomeButton(context),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderInfoCard() {
    String formattedId = widget.orderId
        .substring(widget.orderId.length > 8 ? widget.orderId.length - 8 : 0);
    String arrivalMsg = _currentStatus.toLowerCase() == 'delivered'
        ? 'Delivered'
        : 'Arriving Soon';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                    'Order ID: #$formattedId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    arrivalMsg,
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
          _buildItemSummary(),
        ],
      ),
    );
  }

  Widget _buildItemSummary() {
    final items = (_orderData?['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.set_meal, size: 40, color: Color(0xFF68B92E)),
          SizedBox(width: 12),
          Text('Order items', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
    }

    return Column(
      children: items.map<Widget>((item) {
        final product = item['product'] as Map<String, dynamic>?;
        final name =
            product?['name']?.toString() ?? item['name']?.toString() ?? 'Item';
        final qty = item['quantity']?.toString() ?? '1';
        final price = (item['price'] as num?)?.toDouble() ??
            (product?['price'] as num?)?.toDouble() ??
            0.0;
        final images = product?['images'] as List<dynamic>? ?? [];
        final imgUrl = images.isNotEmpty ? images.first.toString() : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imgUrl.isNotEmpty
                    ? Image.network(imgUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFFF7F8FA),
                              child: const Icon(Icons.set_meal,
                                  color: Color(0xFF68B92E)),
                            ))
                    : Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFFF7F8FA),
                        child: const Icon(Icons.set_meal,
                            color: Color(0xFF68B92E))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Qty: $qty',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                '₹${(price * double.parse(qty)).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF68B92E),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrackingStepper() {
    final s = _currentStatus.toLowerCase();

    // Step 1: Order Placed — always done once we're on tracking page
    const step1Done = true;
    final step1Active = s == 'pending';

    // Step 2: Accepted / Processing
    final step2Done = [
      'accepted',
      'processing',
      'rider assigned',
      'rider accepted',
      'out for delivery',
      'delivered',
      'completed'
    ].contains(s);
    final step2Active = s == 'accepted' || s == 'processing';

    // Step 3: Rider Assigned
    final step3Done = [
      'rider assigned',
      'rider accepted',
      'out for delivery',
      'delivered',
      'completed'
    ].contains(s);
    final step3Active = s == 'rider assigned';

    // Step 4: Rider On the Way (Rider Accepted)
    final step4Done = [
      'rider accepted',
      'out for delivery',
      'delivered',
      'completed'
    ].contains(s);
    final step4Active = s == 'rider accepted' || s == 'out for delivery';

    // Step 5: Delivered
    final step5Done = s == 'delivered' || s == 'completed';
    final step5Active = step5Done;

    return Column(
      children: [
        _buildStepItem(
          'Order Placed',
          '',
          'Your order has been received.',
          isCompleted: step1Done,
          isFirst: true,
          isActive: step1Active,
        ),
        _buildStepItem(
          'Accepted & Processing',
          '',
          'Retailer is preparing your order.',
          isCompleted: step2Done,
          isActive: step2Active,
        ),
        _buildStepItem(
          'Rider Assigned',
          '',
          'A rider has been assigned to your order.',
          isCompleted: step3Done,
          isActive: step3Active,
        ),
        _buildStepItem(
          'Out for Delivery',
          '',
          'Rider is on the way to you!',
          isCompleted: step4Done,
          isActive: step4Active,
        ),
        _buildStepItem(
          'Delivered',
          '',
          'Enjoy your meal! 🎉',
          isCompleted: step5Done,
          isLast: true,
          isActive: step5Active,
        ),
      ],
    );
  }

  Widget _buildStepItem(
    String title,
    String time,
    String description, {
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF68B92E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF68B92E)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF68B92E).withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : isActive
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF68B92E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
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

  Widget _buildDeliveryDetails() {
    final addr = _orderData?['deliveryAddress'] as Map<String, dynamic>?;
    final street =
        addr?['address']?.toString() ?? addr?['fullAddress']?.toString() ?? '';
    final city = addr?['city']?.toString() ?? '';
    final state = addr?['state']?.toString() ?? '';
    final pin = addr?['pincode']?.toString() ?? '';
    final fullAddr =
        [street, city, state, pin].where((s) => s.isNotEmpty).join(', ');
    final totalAmount = (_orderData?['totalAmount'] as num?)?.toDouble();
    final payMethod = _orderData?['paymentMethod']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Color(0xFF68B92E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      fullAddr.isNotEmpty ? fullAddr : 'Address not available',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalAmount != null || payMethod.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F4F8)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (payMethod.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(payMethod,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                if (totalAmount != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF439462))),
                    ],
                  ),
              ],
            ),
          ],
        ],
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
          backgroundColor: const Color(0xFF439462),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Go back to Home',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
