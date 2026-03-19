import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/socket_service.dart';

class OrderTrackingPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  late Map<String, dynamic> _order;
  List<dynamic> _statusHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _statusHistory = List<dynamic>.from(_order['statusHistory'] ?? []);
    
    _loadOrderDetails();
    _setupSocket();
  }

  Future<void> _loadOrderDetails() async {
    final mongoId = _order['_id']?.toString() ?? '';
    if (mongoId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final service = ref.read(orderServiceProvider);
      Map<String, dynamic> freshData = await service.trackOrder(mongoId);

      // Fallback: some order types (e.g. subscription) may not be on /track
      if (freshData.isEmpty) {
        freshData = await service.getOrderById(mongoId);
      }

      if (freshData.isNotEmpty && mounted) {
        setState(() {
          _order = freshData;
          _statusHistory = List<dynamic>.from(_order['statusHistory'] ?? []);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = _order['orderId']?.toString() ?? '';
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
              // Append the new status entry locally
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
    final orderId = _order['orderId']?.toString() ?? '';
    if (orderId.isNotEmpty) {
      ref.read(socketServiceProvider).leaveOrderRoom(orderId);
      ref.read(socketServiceProvider).offEvent('orderUpdate');
    }
    super.dispose();
  }

  // All possible statuses in order
  static const _allStatuses = [
    'Pending',
    'Accepted',
    'Processing',
    'Preparing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'retailer':
        return const Color(0xFF68B92E);
      case 'rider':
        return const Color(0xFFE67E22);
      case 'user':
        return const Color(0xFF3498DB);
      case 'system':
        return const Color(0xFF95A5A6);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('placed')) return Icons.receipt_long_rounded;
    if (s.contains('accepted') && s.contains('rider')) return Icons.delivery_dining_rounded;
    if (s.contains('accepted')) return Icons.check_circle_rounded;
    if (s.contains('processing') || s.contains('preparing')) return Icons.restaurant_rounded;
    if (s.contains('shipped') || s.contains('out for delivery')) return Icons.moped_rounded;
    if (s.contains('delivered')) return Icons.home_rounded;
    return Icons.radio_button_checked_rounded;
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return ts.toString();
    }
  }

  Widget _buildRoleBadge(String role) {
    if (role == 'system') return const SizedBox();
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = const Color(0xFF68B92E);
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'out for delivery':
      case 'rider accepted':
        color = const Color(0xFFE67E22);
        break;
      default:
        color = const Color(0xFF114F3B); // Dark green or grey
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF114F3B)),
        ),
      );
    }

    final status = _order['status'] ?? 'Pending';
    final items = _order['items'] as List<dynamic>? ?? [];

    String itemName = 'Items';
    String qty = '';
    String shopName = '';
    
    if (items.isNotEmpty) {
      final item = items.first;
      final product = item['product'];
      itemName = (product is Map && product['name'] != null) ? product['name'].toString() : 'Item';
      qty = item['quantity']?.toString() ?? '1';
      
      // Attempt to get retailer name
      final retailer = item['retailer'];
      if (retailer is Map) {
        final bizDetails = retailer['businessDetails'];
        if (bizDetails is Map) {
          shopName = bizDetails['storeDisplayName']?.toString() ?? 
                     bizDetails['businessName']?.toString() ?? '';
        }
      }
    }
    final subtitle = items.isNotEmpty ? '${qty}x $itemName' : '';

    final isSub =
        _order['orderType'] == 'Subscription' || _order['frequency'] != null;
    final frequency = _order['frequency']?.toString() ?? 'Daily';
    final customDaysList = _order['customDays'] as List<dynamic>? ?? [];
    final customDaysStr = customDaysList.join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadOrderDetails();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        color: const Color(0xFF114F3B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Information ─────────────────────────────────────────
              Text('Order Details',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('#${_order['orderId'] ?? _order['_id'] ?? ''}',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Refresh to check the latest update on your order.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
              
              if (shopName.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF68B92E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF68B92E).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF68B92E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOLD BY',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              shopName,
                              style: const TextStyle(
                                color: Color(0xFF114F3B),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
              ),

              // ── Current Status ─────────────────────────────────────────────
              const Text('CURRENT STATUS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 10),
              _buildStatusBadge(status),

              // ── Subscription Schedule ──────────────────────────────────────
              if (isSub) ...[
                const SizedBox(height: 20),
                const Text('SUBSCRIPTION SCHEDULE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Text(frequency,
                    style: const TextStyle(
                        color: Color(0xFF68B92E),
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                if (customDaysStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Days: $customDaysStr',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
              ),

              // ── Status History ─────────────────────────────────────────────
              const Text('STATUS HISTORY',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 20),
              _buildTimeline(status),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
              ),

              // ── Delivery Address ───────────────────────────────────────────
              const Text('DELIVERY ADDRESS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 12),
              _buildAddressSection(),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
              ),

              // ── Order Summary (Payment) ─────────────────────────────────────
              _buildOrderSummary(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final totalAmount = _order['totalAmount'];
    final paymentMethod = _order['paymentMethod']?.toString() ?? '';
    final paymentStatus = _order['paymentStatus']?.toString() ?? '';
    final orderType = _order['orderType']?.toString() ?? '';

    if (totalAmount == null && paymentMethod.isEmpty) return const SizedBox();

    Color payStatusColor;
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        payStatusColor = const Color(0xFF68B92E);
        break;
      case 'pending':
        payStatusColor = Colors.orange;
        break;
      case 'failed':
        payStatusColor = Colors.red;
        break;
      default:
        payStatusColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER SUMMARY',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              if (totalAmount != null)
                _summaryRow(
                  'Total Amount',
                  '₹${totalAmount.toString()}',
                  icon: Icons.receipt_long_outlined,
                  valueStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF114F3B)),
                ),
              if (paymentMethod.isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFEEEEEE)),
                _summaryRow(
                  'Payment Method',
                  paymentMethod,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
              if (paymentStatus.isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFEEEEEE)),
                _summaryRow(
                  'Payment Status',
                  paymentStatus,
                  icon: Icons.verified_outlined,
                  valueStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: payStatusColor),
                ),
              ],
              if (orderType.isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFEEEEEE)),
                _summaryRow(
                  'Order Type',
                  orderType,
                  icon: Icons.category_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {IconData? icon, TextStyle? valueStyle}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Text(value,
            style: valueStyle ??
                const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
      ],
    );
  }

  Widget _buildAddressSection() {
    final addr = _order['deliveryAddress'];
    if (addr == null || (addr is Map && addr.isEmpty)) {
      return const Padding(
        padding: EdgeInsets.only(left: 36),
        child: Text('No delivery address specified.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    final street = addr['address'] ?? addr['street'] ?? addr['flat'] ?? addr['houseNo'] ?? '';
    final city = addr['city'] ?? '';
    final state = addr['state'] ?? '';
    final pincode = addr['pincode'] ?? '';
    final landmark = addr['landmark'] ?? '';

    if (street.toString().isEmpty && city.toString().isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 36),
        child: Text('Address details not available.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF114F3B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Color(0xFF114F3B), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                street.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${city.toString()}, ${state.toString()} - ${pincode.toString()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              if (landmark.toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Landmark: ${landmark.toString()}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(String currentStatus) {
    if (_statusHistory.isNotEmpty) {
      return _buildHistoryTimeline();
    }
    return _buildInferredTimeline(currentStatus);
  }

  Widget _buildHistoryTimeline() {
    // Filter duplicates and sequential identical statuses
    final filteredHistory = <dynamic>[];
    String lastStatus = '';
    
    for (var item in _statusHistory) {
      final currentStatus = item['status']?.toString() ?? '';
      if (currentStatus != lastStatus) {
        filteredHistory.add(item);
        lastStatus = currentStatus;
      }
    }

    return Column(
      children: filteredHistory.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == filteredHistory.length - 1;
        final role = item['role']?.toString() ?? 'system';
        final statusText = item['status']?.toString() ?? '';
        final ts = _formatTimestamp(item['timestamp']);
        final color = isLast ? const Color(0xFF68B92E) : Colors.grey.shade400;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _statusIcon(statusText),
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          Colors.grey.shade100,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isLast ? const Color(0xFF114F3B) : const Color(0xFF2C3E50))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (role != 'system') ...[
                          _buildRoleBadge(role),
                          const SizedBox(width: 8),
                        ],
                        Text(ts,
                            style: TextStyle(
                                color: Colors.grey.shade500, 
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInferredTimeline(String currentStatus) {
    final currentIdx = _allStatuses.indexOf(currentStatus);
    return Column(
      children: _allStatuses.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        if (idx > currentIdx && currentIdx != -1) return const SizedBox();

        final isDone = idx <= currentIdx;
        if (!isDone) return const SizedBox();

        final isLast = idx == currentIdx;

        String role = 'system';
        if (s == 'Accepted' || s == 'Processing') role = 'retailer';
        if (s == 'Out for Delivery' ||
            s == 'Delivered' ||
            s.contains('Rider Accepted')) {
          role = 'rider';
        }

        final color = isLast ? const Color(0xFF68B92E) : Colors.grey.shade400;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _statusIcon(s),
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          Colors.grey.shade100,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isLast ? const Color(0xFF114F3B) : const Color(0xFF2C3E50))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (role != 'system') ...[
                          _buildRoleBadge(role),
                          const SizedBox(width: 8),
                        ],
                        const Text('Done',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
