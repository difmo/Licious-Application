import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../data/services/rider_service.dart';
import '../../../data/services/location_tracking_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'rider_history_page.dart';

final riderOrdersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final riderService = ref.watch(riderServiceProvider);
  return riderService.getAssignedOrders();
});

class RiderHomePage extends ConsumerStatefulWidget {
  const RiderHomePage({super.key});

  @override
  ConsumerState<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends ConsumerState<RiderHomePage> {
  bool _isOnline = false;
  int _currentIndex = 0;
  final Set<String> _loadingOrderIds = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    if (_isOnline) {
      await LocationTrackingService.start();
    } else {
      await LocationTrackingService.stop();
    }
  }

  Future<void> _handleResponse(String orderId, String response) async {
    if (_loadingOrderIds.contains(orderId)) return;
    setState(() => _loadingOrderIds.add(orderId));

    try {
      final riderService = ref.read(riderServiceProvider);
      final result = await riderService.respondToOrder(
          orderId: orderId, response: response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Action successful'),
            backgroundColor:
                result['success'] ? AppColors.accentGreen : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (result['success']) {
          ref.invalidate(riderOrdersProvider);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loadingOrderIds.remove(orderId));
      }
    }
  }

  Future<void> _completeDelivery(String orderId) async {
    if (_loadingOrderIds.contains(orderId)) return;
    setState(() => _loadingOrderIds.add(orderId));

    try {
      final riderService = ref.read(riderServiceProvider);
      final result = await riderService.completeOrder(orderId: orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Delivery completed'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(riderOrdersProvider);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingOrderIds.remove(orderId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTasksTab(),
          const RiderHistoryPage(isTab: true),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final ordersAsync = ref.watch(riderOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Assigned Tasks',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isOnline)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Live Tracking Active',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGreen),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 1.seconds)
                    .fadeOut(delay: 1.seconds),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () => ref.invalidate(riderOrdersProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentGreen,
        onRefresh: () async => ref.invalidate(riderOrdersProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (!_isOnline)
                _buildOfflineState()
              else
                ordersAsync.when(
                  data: (orders) {
                    final activeOrders =
                        List<dynamic>.from(orders).where((order) {
                      final status = order['riderAssignmentStatus'] ??
                          order['status'] ??
                          'Pending';
                      final st = status.toString().toLowerCase();
                      return st != 'delivered' && st != 'completed';
                    }).toList();

                    final sortedOrders = List<dynamic>.from(activeOrders);
                    sortedOrders.sort((a, b) {
                      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ??
                          DateTime(0);
                      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ??
                          DateTime(0);
                      return dateB.compareTo(dateA); // Newest first
                    });

                    if (sortedOrders.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sortedOrders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(sortedOrders[index]);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentGreen)),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEBFFD7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: Color(0xFF68B92E),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Rider Name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2D1F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.phoneNumber ?? '9876543211',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Switch.adaptive(
                              value: _isOnline,
                              activeTrackColor:
                                  AppColors.accentGreen.withOpacity(0.5),
                              activeThumbColor: AppColors.accentGreen,
                              onChanged: _toggleOnline,
                            ),
                            Text(
                              _isOnline ? 'ONLINE' : 'OFFLINE',
                              style: TextStyle(
                                color: _isOnline
                                    ? AppColors.accentGreen
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_isOnline) ...[
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Consumer(builder: (context, ref, child) {
                            final history = ref.watch(riderHistoryProvider);
                            final count = history.maybeWhen(
                              data: (d) => d.length.toString(),
                              orElse: () => '...',
                            );
                            return _buildStat(
                                'Completed', count, Icons.delivery_dining);
                          }),
                          _buildStat('Rating', '4.8', Icons.star_rounded),
                          Consumer(builder: (context, ref, child) {
                            final history = ref.watch(riderHistoryProvider);
                            final earnings = history.maybeWhen(
                              data: (orders) {
                                final total = orders.fold<num>(
                                    0,
                                    (sum, item) =>
                                        sum + (item['totalAmount'] ?? 0));
                                return '₹${total.toStringAsFixed(0)}';
                              },
                              orElse: () => '₹...',
                            );
                            return _buildStat('Earnings', earnings,
                                Icons.account_balance_wallet_rounded);
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8EB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentGreen, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF1B2D1F),
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final rawStatus = (order['riderAssignmentStatus'] ??
            order['orderStatus'] ??
            order['status'] ??
            'Pending')
        .toString();
    final stLower = rawStatus.toLowerCase();

    // ── Button visibility per new flow ──────────────────────────
    // Show Accept/Reject when the rider is newly assigned (Rider Assigned)
    // or when order is still Pending/Processing (legacy fallback)
    final showAcceptReject = stLower == 'rider assigned' ||
        stLower == 'pending' ||
        stLower == 'processing';

    // Show "Mark as Delivered" only once rider has accepted
    final showMarkDelivered =
        stLower == 'rider accepted' || stLower == 'accepted'; // legacy fallback

    final isTerminal = stLower == 'delivered' || stLower == 'completed';
    final isLoading = _loadingOrderIds.contains(order['orderId']);

    // ── Status pill colors ───────────────────────────────────────
    Color statusColor = Colors.white;
    Color statusBgColor;
    IconData statusIcon;

    switch (stLower) {
      case 'delivered':
      case 'completed':
        statusBgColor = const Color(0xFF16A62A);
        statusIcon = Icons.check_circle;
        break;
      case 'rider accepted':
        statusBgColor = const Color(0xFF0056D2); // deep blue
        statusIcon = Icons.directions_bike_rounded;
        break;
      case 'accepted':
        statusBgColor = const Color(0xFF0F6AD3);
        statusIcon = Icons.check_circle;
        break;
      case 'rider assigned':
        statusBgColor = const Color(0xFF7B2FBE); // purple
        statusIcon = Icons.person_pin_circle_rounded;
        break;
      case 'processing':
        statusBgColor = const Color(0xFF0097A7); // teal
        statusIcon = Icons.access_time;
        break;
      case 'pending':
        statusBgColor = const Color(0xFFF1A500);
        statusIcon = Icons.access_time;
        break;
      default:
        statusBgColor = const Color(0xFFFFA000);
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F4F8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBFFD7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order['orderId'].toString().substring(order['orderId'].toString().length - 6).toUpperCase()}',
                        style: const TextStyle(
                          color: Color(0xFF439462),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rawStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      order['dateTime'] ?? _formatDate(order['createdAt']),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOrderInfoRow(
                  Icons.location_on_rounded,
                  'Delivery Address',
                  _formatAddress(order['address'] ?? order['deliveryAddress']),
                ),
                const SizedBox(height: 12),
                _buildOrderInfoRow(
                  Icons.person_rounded,
                  'Customer',
                  order['customerName'] ??
                      order['user']?['fullName'] ??
                      'Customer',
                ),
                const SizedBox(height: 12),
                _buildOrderInfoRow(
                  Icons.phone_rounded,
                  'Phone Number',
                  order['phoneNumber'] ??
                      order['user']?['phoneNumber'] ??
                      'Unknown',
                ),
                const SizedBox(height: 12),
                _buildOrderInfoRow(
                  Icons.shopping_bag_outlined,
                  'Items',
                  _formatItems(order['items']),
                ),
                const SizedBox(height: 12),
                _buildOrderInfoRow(
                  Icons.wallet_rounded,
                  'Payment & Total',
                  '${order['paymentMethod'] ?? 'Wallet'} - ₹${order['totalAmount'] ?? '0.0'}',
                ),
              ],
            ),
          ),
          // ── Accept / Reject buttons (for newly assigned or pending) ──
          if (showAcceptReject && !isTerminal)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _handleResponse(order['orderId'], 'Accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF68B92E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Accept Order',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => _handleResponse(order['orderId'], 'Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                            color: isLoading ? Colors.grey : Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            )
          // ── Mark as Delivered button (for rider accepted) ──────────────
          else if (showMarkDelivered && !isTerminal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _completeDelivery(order['orderId']),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(isLoading ? 'Processing...' : 'Mark as Delivered',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF68B92E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOrderInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F4F8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1B2D1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8EB),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delivery_dining_rounded,
                size: 80,
                color: const Color(0xFF68B92E).withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            'All clear! No pending tasks.',
            style: TextStyle(
                color: Color(0xFF1B2D1F),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Go online to receive new orders',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  String _formatAddress(dynamic addr) {
    if (addr == null || addr is! Map) return 'No address provided';
    final parts = [
      addr['address'],
      addr['city'],
      addr['state'],
      addr['pincode'],
    ].where((e) => e != null && e.toString().isNotEmpty).toList();
    return parts.isEmpty ? 'No address details' : parts.join(', ');
  }

  String _formatItems(dynamic items) {
    if (items == null || items is! List) return 'No items';
    return items.map((e) {
      final name = e['name'] ?? e['product']?['name'] ?? 'Unknown Item';
      return '$name (x${e['quantity']})';
    }).join(', ');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour;
      final min = date.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'pm' : 'am';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$day-$month-$year, $hour12:$min $ampm';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.power_settings_new_rounded,
                size: 80, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'You are currently offline',
            style: TextStyle(
                color: Color(0xFF1B2D1F),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Go online to view your assigned tasks',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
