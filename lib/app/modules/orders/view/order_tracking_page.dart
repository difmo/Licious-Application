import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _statusHistory = List<dynamic>.from(_order['statusHistory'] ?? []);

    // Join the order room to receive live updates
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
    switch (role) {
      case 'retailer':
        return const Color(0xFF114F3B);
      case 'rider':
        return const Color(0xFFE67E22);
      case 'user':
        return const Color(0xFF3498DB);
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'retailer':
        return Icons.store;
      case 'rider':
        return Icons.delivery_dining;
      case 'user':
        return Icons.person;
      default:
        return Icons.settings;
    }
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

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] ?? 'Pending';
    final rider = _order['rider'];
    final items = _order['items'] as List<dynamic>? ?? [];
    final retailer = items.isNotEmpty ? items.first['retailer'] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Track Order',
            style: TextStyle(
                color: Color(0xFF114F3B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF114F3B), Color(0xFF1A7A5B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('Order #${_order['orderId'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      if (_order['orderType'] == 'Subscription')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Sub',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(status,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Status History Timeline ─────────────────────────────────────
            const Text('Status Timeline',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            _buildTimeline(status),

            const SizedBox(height: 24),

            // ── Rider Info ──────────────────────────────────────────────────
            if (rider != null) ...[
              const Text('Rider',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 12),
              _buildContactCard(
                icon: Icons.delivery_dining,
                color: const Color(0xFFE67E22),
                name: rider is Map
                    ? (rider['name']?.toString() ?? 'Rider')
                    : rider.toString(),
                phone: rider is Map ? rider['phone']?.toString() : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Retailer Info ────────────────────────────────────────────────
            if (retailer != null) ...[
              const Text('Retailer',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 12),
              _buildContactCard(
                icon: Icons.store,
                color: const Color(0xFF114F3B),
                name: retailer is Map
                    ? (retailer['businessDetails']?['storeDisplayName'] ??
                        retailer['name'] ??
                        'Retailer')
                    : 'Retailer',
                phone: retailer is Map ? retailer['phone']?.toString() : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Items ────────────────────────────────────────────────────────
            const Text('Items',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            ...(items.map((item) {
              final product = item['product'];
              final name = product is Map
                  ? product['name']?.toString() ?? 'Product'
                  : 'Product';
              final qty = item['quantity']?.toString() ?? '1';
              final price = (item['price'] as num?)?.toDouble() ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.set_meal,
                        color: Color(0xFF114F3B), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('${qty}x · ₹${price.toStringAsFixed(0)}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              );
            })),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    // Show history entries if available, otherwise show inferred timeline
    if (_statusHistory.isNotEmpty) {
      return _buildHistoryTimeline();
    }
    return _buildInferredTimeline(currentStatus);
  }

  Widget _buildHistoryTimeline() {
    return Column(
      children: _statusHistory.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == _statusHistory.length - 1;
        final role = item['role']?.toString() ?? 'system';
        final statusText = item['status']?.toString() ?? '';
        final ts = _formatTimestamp(item['timestamp']);
        final color = _roleColor(role);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(_roleIcon(role), size: 18, color: color),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey.shade200),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(
                      '${role[0].toUpperCase()}${role.substring(1)} · $ts',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
        final isDone = idx <= currentIdx;
        final isCurrent = idx == currentIdx;
        final isLast = idx == _allStatuses.length - 1;
        final color = isDone ? const Color(0xFF114F3B) : Colors.grey.shade300;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF114F3B).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey.shade200),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Text(s,
                    style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: isCurrent ? 15 : 14,
                        color: isDone
                            ? const Color(0xFF114F3B)
                            : Colors.grey.shade400)),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String name,
    String? phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (phone != null && phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              icon: Icon(Icons.call, color: color),
              onPressed: () async {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
        ],
      ),
    );
  }
}
