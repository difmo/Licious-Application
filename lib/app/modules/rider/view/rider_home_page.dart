import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:geolocator/geolocator.dart'; // disabled for testing
import '../../auth/provider/auth_provider.dart';
import '../../../data/services/rider_service.dart';
// import '../../../data/services/location_tracking_service.dart'; // disabled for testing
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'rider_order_details_page.dart';

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
  bool _isTogglingStatus = false;

  // NOTE: _activeStatuses, _ensureLocationPermission, _checkLocationPermission,
  // and _hasActiveDelivery are all disabled for testing. Re-enable in production.
  // static const _activeStatuses = {'assigned', 'out_for_delivery', 'arrived'};

  @override
  void initState() {
    super.initState();
    // _checkLocationPermission(); // disabled for testing
  }

  /*  ── Location helpers (re-enable for production) ──────────────────────────
  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { ... }
    ...
    return true;
  }
  bool _hasActiveDelivery(List<dynamic> orders) {
    return orders.any((o) {
      final status = (o['status']?.toString() ?? '').toLowerCase();
      return _activeStatuses.contains(status);
    });
  }
  */

  Future<void> _toggleOnline(bool value) async {
    if (_isTogglingStatus) return;
    setState(() => _isTogglingStatus = true);

    try {
      // ── Going ONLINE ────────────────────────────────────────────────────
      if (value) {
        // NOTE: Location check disabled for testing — re-enable in production
        // final hasPermission = await _ensureLocationPermission();
        // if (!hasPermission) { setState(() => _isTogglingStatus = false); return; }

        // Call backend PATCH /rider/status { status: 'online' }
        final riderService = ref.read(riderServiceProvider);
        final result = await riderService.updateStatus('online');

        if (result['success'] == false) {
          if (mounted) {
            _showSnack(result['message'] ?? 'Failed to go online',
                isError: true);
          }
          setState(() => _isTogglingStatus = false);
          return;
        }

        // NOTE: LocationTracking disabled for testing — re-enable in production
        // await LocationTrackingService.start();
        if (mounted) {
          setState(() => _isOnline = true);
          _showSnack('You are now ONLINE ✅');
          ref.invalidate(riderOrdersProvider);
        }

        // ── Going OFFLINE ───────────────────────────────────────────────────
      } else {
        // NOTE: Active delivery block disabled for testing — re-enable in production
        // final ordersAsyncValue = ref.read(riderOrdersProvider);
        // final orders = ordersAsyncValue.value ?? [];
        // if (_hasActiveDelivery(orders)) { ... return; }

        // Call backend PATCH /rider/status { status: 'offline' }
        final riderService = ref.read(riderServiceProvider);
        final result = await riderService.updateStatus('offline');

        if (result['success'] == false) {
          if (mounted) {
            _showSnack(result['message'] ?? 'Failed to go offline',
                isError: true);
          }
          setState(() => _isTogglingStatus = false);
          return;
        }

        // NOTE: LocationTracking disabled for testing — re-enable in production
        // await LocationTrackingService.stop();
        if (mounted) {
          setState(() => _isOnline = false);
          _showSnack('You are now OFFLINE');
          ref.invalidate(riderOrdersProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: isError ? Colors.redAccent : AppColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  /* _showAlert — re-enable with location helpers in production
  void _showAlert({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0E0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.orange, size: 32),
        ),
        title: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
  */

  Future<void> _handleResponse(String orderId, String response) async {
    final riderService = ref.read(riderServiceProvider);
    final result =
        await riderService.respondToOrder(orderId: orderId, response: response);

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
  }

  Future<void> _markDelivered(String orderId) async {
    final riderService = ref.read(riderServiceProvider);
    final result = await riderService.markAsDelivered(orderId: orderId);

    if (mounted) {
      final isSuccess = result['success'] != false;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSuccess
                      ? '✅ Order Delivered Successfully!'
                      : result['message'] ?? 'Failed to mark as delivered',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isSuccess ? AppColors.accentGreen : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      if (isSuccess) {
        ref.invalidate(riderOrdersProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final ordersAsync = ref.watch(riderOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Rider Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(riderOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
          const SizedBox(width: 8),
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
              // ── Rider Profile Card ──────────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
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
                              if (_isTogglingStatus)
                                const SizedBox(
                                  width: 40,
                                  height: 28,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.accentGreen,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Switch.adaptive(
                                  value: _isOnline,
                                  activeTrackColor: AppColors.accentGreen
                                      .withValues(alpha: 0.5),
                                  activeThumbColor: AppColors.accentGreen,
                                  onChanged:
                                      _isTogglingStatus ? null : _toggleOnline,
                                ),
                              Text(
                                _isTogglingStatus
                                    ? 'LOADING'
                                    : _isOnline
                                        ? 'ONLINE'
                                        : 'OFFLINE',
                                style: TextStyle(
                                  color: _isTogglingStatus
                                      ? Colors.orange
                                      : _isOnline
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
                            _buildStat('Orders', '12', Icons.delivery_dining),
                            _buildStat('Rating', '4.8', Icons.star_rounded),
                            _buildStat('Earnings', '₹1,240',
                                Icons.account_balance_wallet_rounded),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assigned Tasks',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B2D1F)),
                    ),
                    if (_isOnline)
                      Text(
                        'Live Tracking Active',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGreen),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 1.seconds)
                          .fadeOut(delay: 1.seconds),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
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
    final assignmentStatus = order['riderAssignmentStatus'];
    final orderStatus =
        (order['status']?.toString() ?? 'Pending').toLowerCase();

    final isPending = assignmentStatus == 'Pending';
    final isAccepted = assignmentStatus == 'Accepted';
    final isDelivered =
        orderStatus == 'delivered' || orderStatus == 'completed';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiderOrderDetailsPage(order: order),
        ),
      ),
      child: Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBFFD7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${(order['orderId']?.toString() ?? '').length >= 6 ? order['orderId'].toString().substring(order['orderId'].toString().length - 6).toUpperCase() : (order['orderId']?.toString() ?? '').toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF439462),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (order['orderType'] == 'Subscription') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.purple.shade100),
                              ),
                              child: Text(
                                'SUBSCRIPTION',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                          if (order['hasExtras'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                '+ EXTRAS',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (order['status']?.toString() ?? 'UNKNOWN')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFFA000),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildOrderInfoRow(
                    Icons.location_on_rounded,
                    'Delivery Address',
                    (order['deliveryAddress'] is Map)
                        ? (order['deliveryAddress']['address']?.toString() ??
                            'No address provided')
                        : 'No address provided',
                  ),
                  const SizedBox(height: 12),
                  _buildOrderInfoRow(
                    Icons.person_rounded,
                    'Customer',
                    (order['user'] is Map)
                        ? (order['user']['fullName']?.toString() ??
                                order['user']['name']?.toString() ??
                                'Customer')
                            .toUpperCase()
                        : 'CUSTOMER',
                  ),
                  _buildOrderInfoRow(
                    Icons.shopping_bag_rounded,
                    'Order Type',
                    (order['orderType']?.toString() ??
                            order['order_type']?.toString() ??
                            'Regular')
                        .toUpperCase(),
                  ),
                ],
              ),
            ),
            if (isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleResponse(order['orderId'], 'Accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF68B92E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Accept Order',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _handleResponse(order['orderId'], 'Rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
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
            else if (isAccepted && !isDelivered)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Left: Out for Delivery
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await ref
                              .read(riderServiceProvider)
                              .updateDeliveryStatus(
                                orderId: order['orderId'],
                                status: 'Out for Delivery',
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  result['message'] ?? '🚚 Out for Delivery!'),
                              backgroundColor: AppColors.accentGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ));
                            ref.invalidate(riderOrdersProvider);
                          }
                        },
                        icon:
                            const Icon(Icons.delivery_dining_rounded, size: 16),
                        label: const Text('Out for\nDelivery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentGreen,
                          side: BorderSide(color: AppColors.accentGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: Mark as Delivered
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markDelivered(order['orderId']),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Mark as\nDelivered',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF68B92E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
}
