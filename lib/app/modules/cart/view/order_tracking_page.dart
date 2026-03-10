import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/socket_service.dart';

class OrderTrackingPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? order;
  const OrderTrackingPage({super.key, this.order});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  late Map<String, dynamic> _order;
  List<dynamic> _statusHistory = [];


  @override
  void initState() {
    super.initState();
    _order = widget.order != null ? Map<String, dynamic>.from(widget.order!) : {};
    _statusHistory = List<dynamic>.from(_order['statusHistory'] ?? []);
    
    // Join the order room to receive live updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = _order['_id']?.toString() ?? _order['orderId']?.toString() ?? '';
      if (orderId.isNotEmpty) {
        final socket = ref.read(socketServiceProvider);
        socket.joinOrderRoom(orderId);
        socket.onOrderUpdate((data) {
          if (!mounted) return;
          setState(() {
            _order['status'] = data['status'] ?? _order['status'];
            if (data['statusHistory'] != null) {
              _statusHistory = List<dynamic>.from(data['statusHistory']);
            } else {
              _statusHistory.add({
                'status': data['status'],
                'role': 'system',
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    final orderId = _order['_id']?.toString() ?? _order['orderId']?.toString() ?? '';
    if (orderId.isNotEmpty) {
      ref.read(socketServiceProvider).leaveOrderRoom(orderId);
      ref.read(socketServiceProvider).offEvent('orderUpdate');
    }
    super.dispose();
  }

  // All possible delivery statuses
  static const _allStatuses = [
    'Pending',
    'Accepted',
    'Processing',
    'Preparing',
    'Packed',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Track Order',
              style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: const Center(child: Text("No order details found.")),
      );
    }

    final status = _order['status'] ?? 'Pending';
    final currentIdx = _allStatuses.contains(status) ? _allStatuses.indexOf(status) : 0;
    final orderIdDisplay = _order['orderId'] ?? _order['_id']?.toString().substring(0, 8) ?? 'Unknown';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfoCard(orderIdDisplay, status),
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
            _buildTrackingStepper(status, currentIdx),
            const SizedBox(height: 24),
            _buildDeliveryDetails(),
            const SizedBox(height: 32),
            _buildGoHomeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(String orderId, String status) {
    final items = _order['items'] as List<dynamic>? ?? [];
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
                    'Order ID: #$orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'Delivered' ? 'Order Delivered' : 'Arriving in 25-30 mins',
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
          if (items.isNotEmpty) _buildItemSummary(items.first) else const Text("No items"),
        ],
      ),
    );
  }

  Widget _buildItemSummary(dynamic item) {
    final product = item['product'] is Map ? item['product'] : {};
    final title = product['name']?.toString() ?? 'Item';
    final quantity = item['quantity']?.toString() ?? '1';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.set_meal, color: Colors.grey),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF439462),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  quantity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'High Quality',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF68B92E),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingStepper(String currentStatus, int currentIdx) {
    // We map out key stages from _allStatuses for simplicity
    final Map<String, String> stages = {
      'Pending': 'Your order has been received.',
      'Processing': 'Our experts are picking the freshest catch.',
      'Packed': 'Waiting for the delivery partner.',
      'Out for Delivery': 'Your order is on the way!',
      'Delivered': 'Your order has been safely delivered.'
    };

    final steps = stages.keys.toList();
    final stepDescriptions = stages.values.toList();
    
    // Find highest matching index
    int displayIdx = 0;
    for (int i = 0; i < steps.length; i++) {
        if (_allStatuses.indexOf(steps[i]) <= currentIdx) {
            displayIdx = i;
        }
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final stepName = entry.value;
        final isCompleted = i < displayIdx || (i == displayIdx && stepName == 'Delivered');
        final isActive = i == displayIdx && stepName != 'Delivered';
        final isLast = i == steps.length - 1;
        
        // Find timestamp if available from status history
        final historyItem = _statusHistory.cast<Map<String,dynamic>>().firstWhere(
            (h) => h['status'] == stepName, 
            orElse: () => <String,dynamic>{}
        );
        String timeStr = historyItem.isNotEmpty ? _formatTimestamp(historyItem['timestamp']) : (isCompleted ? 'Done' : 'Est.');

        return _buildStepItem(
          stepName,
          timeStr,
          stepDescriptions[i],
          isCompleted: isCompleted,
          isActive: isActive,
          isLast: isLast,
        );
      }).toList(),
    );
  }

  Widget _buildStepItem(
    String title,
    String time,
    String description, {
    bool isCompleted = false,
    bool isActive = false,
    bool isLast = false,
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
                  color: isCompleted ? const Color(0xFF68B92E) : Colors.grey.shade300,
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
                color: isCompleted ? const Color(0xFF68B92E) : Colors.grey.shade300,
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
                      color: isCompleted || isActive ? const Color(0xFF1A1A1A) : Colors.grey,
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
                  color: isCompleted || isActive ? Colors.grey.shade600 : Colors.grey.shade400,
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
    final addrMap = _order['deliveryAddress'];
    final addressLine = addrMap is Map 
        ? '${addrMap['address'] ?? ''}, ${addrMap['city'] ?? ''}'
        : 'Unknown Address';

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
                  addressLine,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
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


