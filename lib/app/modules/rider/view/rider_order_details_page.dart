import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rider_service.dart';
import '../../../data/services/socket_service.dart';
import 'rider_home_page.dart';

final orderDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orderId) async {
  final result = await ref.read(riderServiceProvider).getOrderDetails(orderId);
  return result;
});

class RiderOrderDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;

  const RiderOrderDetailsPage({super.key, required this.order});

  @override
  ConsumerState<RiderOrderDetailsPage> createState() =>
      _RiderOrderDetailsPageState();
}

class _RiderOrderDetailsPageState extends ConsumerState<RiderOrderDetailsPage> {
  bool _isLoading = false;

  /// Live-updated status from Socket.IO (falls back to the initial order status)
  late String _liveStatus;

  @override
  void initState() {
    super.initState();
    _liveStatus = widget.order['status']?.toString() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSocket());
  }

  void _initSocket() {
    final orderId = widget.order['orderId']?.toString() ?? '';
    if (orderId.isEmpty) return;

    final socket = ref.read(socketServiceProvider);
    // Join the order-specific room for real-time updates
    socket.joinOrderRoom(orderId);

    // Listen for status changes emitted by the server
    socket.onOrderUpdate((data) {
      if (!mounted) return;
      final incomingId = data?['orderId']?.toString() ?? '';
      if (incomingId != orderId && incomingId.isNotEmpty)
        return; // not our order

      final newStatus = data?['status']?.toString() ?? '';
      if (newStatus.isNotEmpty && newStatus != _liveStatus) {
        setState(() => _liveStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📍 Status updated: $newStatus'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }

      // Also refresh the home list so it stays in sync
      ref.invalidate(riderOrdersProvider);
    });
  }

  @override
  void dispose() {
    final orderId = widget.order['orderId']?.toString() ?? '';
    if (orderId.isNotEmpty) {
      ref.read(socketServiceProvider).leaveOrderRoom(orderId);
      ref.read(socketServiceProvider).offOrderUpdate();
    }
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    final orderId = widget.order['orderId'].toString();
    final riderService = ref.read(riderServiceProvider);

    Map<String, dynamic> result;

    if (status == 'Accepted' || status == 'Rejected') {
      result = await riderService.respondToOrder(
        orderId: orderId,
        response: status,
      );
    } else if (status == 'Delivered') {
      result = await riderService.markAsDelivered(orderId: orderId);
    } else {
      result = await riderService.updateDeliveryStatus(
        orderId: orderId,
        status: status,
      );
    }

    setState(() => _isLoading = false);
    if (mounted) {
      final isSuccess = result['success'] != false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Status updated: $status'),
        backgroundColor: isSuccess ? AppColors.accentGreen : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      ref.invalidate(riderOrdersProvider);
      if (isSuccess && (status == 'Delivered' || status == 'Rejected')) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _callCustomer(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $phone')));
    }
  }

  Future<void> _openMaps(dynamic address) async {
    final addr = address?['address']?.toString() ?? '';
    if (addr.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No address available')));
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final user = order['user'];
    final customerName = (user is Map)
        ? (user['fullName']?.toString() ??
            user['name']?.toString() ??
            'Customer')
        : 'Customer';
    final customerPhone = (user is Map)
        ? (user['phoneNumber']?.toString() ?? user['phone']?.toString() ?? '')
        : '';
    final deliveryAddressMap = order['deliveryAddress'];
    final deliveryAddress = (deliveryAddressMap == null)
        ? 'N/A'
        : (deliveryAddressMap is Map)
            ? (deliveryAddressMap['fullAddress'] ??
                    deliveryAddressMap['address'] ??
                    deliveryAddressMap['street'] ??
                    'N/A')
                .toString()
            : deliveryAddressMap.toString();

    // Use live status from socket, falls back to initial order status
    final status = _liveStatus.isNotEmpty
        ? _liveStatus
        : (order['status']?.toString() ?? '');
    final orderId = order['orderId']?.toString() ?? '';
    final shortId = orderId.length >= 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();
    final paymentType = (order['paymentMethod'] ??
            order['paymentType'] ??
            order['payment_method'] ??
            'N/A')
        .toString();
    final instructions = order['deliveryInstructions']?.toString() ??
        order['instructions']?.toString() ??
        'None';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('#$shortId',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Actions ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Call Customer',
                    color: Colors.blue,
                    onTap: () => _callCustomer(customerPhone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.map_rounded,
                    label: 'Open Maps',
                    color: Colors.orange,
                    onTap: () => _openMaps(deliveryAddress),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // ── Customer Info ─────────────────────────────────────────────
            _SectionCard(
              title: 'Customer',
              child: Column(
                children: [
                  _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Name',
                      value: customerName),
                  if (customerPhone.isNotEmpty)
                    _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: customerPhone),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: deliveryAddress,
                    iconColor: Colors.red,
                  ),
                  if (instructions != 'None')
                    _InfoRow(
                        icon: Icons.notes_rounded,
                        label: 'Instructions',
                        value: instructions),
                ],
              ),
            ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // ── Order Info ────────────────────────────────────────────────
            _SectionCard(
              title: 'Order Info',
              child: Column(
                children: [
                  _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Order ID',
                      value: '#$shortId'),
                  _InfoRow(
                      icon: Icons.payment_rounded,
                      label: 'Payment',
                      value: paymentType),
                  _InfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Status',
                      value: status.toUpperCase()),
                ],
              ),
            ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // ── Items ─────────────────────────────────────────────────────
            if (items.isNotEmpty)
              _SectionCard(
                title: 'Items (${items.length})',
                child: Column(
                  children: items.map((item) {
                    final product = item['product'];
                    final name = (product is Map)
                        ? (product['name']?.toString() ?? 'Item')
                        : (item['name']?.toString() ?? 'Item');
                    final qty = item['quantity']?.toString() ?? '1';
                    final price = item['price']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F8),
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(qty,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500))),
                          if (price.isNotEmpty)
                            Text('₹$price',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentGreen)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // ── Status Buttons ────────────────────────────────────────────
            if (_isLoading)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accentGreen))
            else if (status.toLowerCase() != 'delivered' &&
                status.toLowerCase() != 'completed')
              Column(
                children: [
                  if (status.toLowerCase() == 'pending' ||
                      status.toLowerCase() == 'preparing' ||
                      status.toLowerCase() == 'accepted' ||
                      status.toLowerCase() == 'rider accepted' ||
                      status.toLowerCase() == 'rider_accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('Out for Delivery'),
                        icon: const Icon(Icons.delivery_dining_rounded),
                        label: const Text('Start Delivery (Out for Delivery)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )
                  else if (status.toLowerCase() == 'rider assigned' ||
                      status.toLowerCase() == 'rider_assigned')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus('Accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Accept',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus('Rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Reject',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  else if (status.toLowerCase() == 'out for delivery' ||
                      status.toLowerCase() == 'out_for_delivery')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('Arrived'),
                        icon: const Icon(Icons.location_on_rounded),
                        label: const Text('I Have Arrived',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )
                  else if (status.toLowerCase() == 'arrived')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('Delivered'),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Mark as Delivered',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                ],
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.iconColor = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
