import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/subscription_service.dart';
import '../../data/services/order_service.dart';
import '../../data/services/db_service.dart';
import '../../core/utils/date_utils.dart';
import '../orders/view/order_tracking_page.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  DateTime _selectedDate = DateTime.now();
  late final DateTime _startDate;

  @override
  void initState() {
    super.initState();
    // Show 3 days in the past and scroll forward from there
    _startDate = DateTime.now().subtract(const Duration(days: 3));
  }

  /// Returns true if the subscription delivers on the given date
  bool _deliversOn(UserSubscription sub, DateTime date) {
    // Check if date is before subscription start
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart =
        DateTime(sub.startDate.year, sub.startDate.month, sub.startDate.day);
    if (normalizedDate.isBefore(normalizedStart)) return false;

    // Check if endDate passed
    if (sub.endDate != null) {
      final normalizedEnd =
          DateTime(sub.endDate!.year, sub.endDate!.month, sub.endDate!.day);
      if (normalizedDate.isAfter(normalizedEnd)) return false;
    }

    // Check vacation dates
    final isOnVacation = sub.vacationDates
        .any((vd) => DateTime(vd.year, vd.month, vd.day) == normalizedDate);
    if (isOnVacation) return false;

    // Check frequency
    switch (sub.frequency) {
      case 'Daily':
        return true;
      case 'Alternate Days':
        final diff = normalizedDate.difference(normalizedStart).inDays;
        return diff % 2 == 0;
      case 'Weekly':
        // customDays holds selected days e.g. ['Sunday', 'Wednesday']
        const dayNames = [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday'
        ];
        final dayName = dayNames[date.weekday % 7];
        return sub.customDays.contains(dayName);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(mySubscriptionsProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final cart = CartProviderScope.of(context);
    final balance = cart.walletBalance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mySubscriptionsProvider);
            ref.invalidate(myOrdersProvider);
            CartProviderScope.read(context).syncWallet();
          },
          color: const Color(0xFF68B92E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(balance),
              _buildHorizontalCalendar(subscriptionsAsync),
              Expanded(
                child: subscriptionsAsync.when(
                  data: (subs) => ordersAsync.when(
                    data: (orders) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatusCard(subs, orders),
                            const SizedBox(height: 20),
                            _buildYourPlans(subs),
                            const SizedBox(height: 30),
                            _buildQuickActions(subs),
                            _buildVacationNote(),
                          ],
                        ),
                    ),
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF68B92E))),
                    error: (e, _) =>
                        Center(child: Text('Error loading orders: $e')),
                  ),
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF68B92E))),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Deliveries',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
                Text(DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
          // Wallet balance pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF68B92E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF68B92E).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF68B92E), size: 16),
                const SizedBox(width: 6),
                Text('₹${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar(
      AsyncValue<List<UserSubscription>> subsAsync) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = _startDate.add(Duration(days: index));
          final ymd = AppDateUtils.formatDate(date);
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month;

          // Determine if date is in the past
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final isPast = date.isBefore(today);

          // Logic: Only show vacation/pause icons for Today or Future dates
          final isVacation = !isPast && 
            subsAsync.maybeWhen(
              data: (subs) {
                final deliverableOnThisDay =
                    subs.where((s) => _deliversOn(s, date)).toList();
                if (deliverableOnThisDay.isEmpty) return false;
                
                // It's a "Vacation" day if every sub that is supposed to deliver is either:
                // 1. Individually paused (status == 'Paused')
                // 2. On a specific vacation date
                return deliverableOnThisDay.every((s) =>
                    s.status == 'Paused' ||
                    s.vacationDates.any((vd) => AppDateUtils.formatDate(vd) == ymd));
              },
              orElse: () => false,
            );

          // Show dot if any ACTIVE subscriptions deliver that day (and not currently paused)
          final hasSub = subsAsync.maybeWhen(
            data: (subs) =>
                subs.any((s) => s.status == 'Active' && _deliversOn(s, date)),
            orElse: () => false,
          );

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                // Task 2: Gray background for vacation dates
                color: isSelected
                    ? const Color(0xFF68B92E)
                    : (isVacation ? Colors.grey.shade200 : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(
                        color: const Color(0xFF68B92E).withValues(alpha: 0.4))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(date.day.toString(),
                      style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : (isVacation ? Colors.grey : Colors.black),
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  if (isVacation)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.pause_circle_outline,
                          size: 14, color: (isSelected ? Colors.white70 : Colors.grey)),
                    ),
                  // Dot logic: Hide dot if it's a vacation date
                  if (hasSub && !isVacation)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? Colors.white : const Color(0xFF68B92E),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(List<UserSubscription> subs, List<dynamic> orders) {
    // 1. Find subscriptions that should deliver on this date
    final deliveringSubs = subs
        .where((s) => s.status == 'Active' && _deliversOn(s, _selectedDate))
        .toList();

    // 2. Find real orders created for this date
    // We assume the order's createdAt or custom field matches the date
    final ordersForDate = orders.where((o) {
      if (o is! Map) return false;
      final createdAtStr = o['createdAt']?.toString();
      if (createdAtStr == null) return false;
      try {
        final orderDate = DateTime.parse(createdAtStr);
        return orderDate.day == _selectedDate.day &&
            orderDate.month == _selectedDate.month &&
            orderDate.year == _selectedDate.year;
      } catch (_) {
        return false;
      }
    }).toList();

    final hasDelivery = deliveringSubs.isNotEmpty || ordersForDate.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBFFD7).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF68B92E).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasDelivery ? const Color(0xFF68B92E) : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDelivery ? 'SCHEDULED' : 'NO DELIVERY',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (ordersForDate.isNotEmpty) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT STATUS',
                      style: TextStyle(
                        color: Color(0xFF8E99AF),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBFFD7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF68B92E).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        (ordersForDate.isNotEmpty &&
                                    ordersForDate.first['status'] != null
                                ? ordersForDate.first['status'].toString()
                                : 'PENDING')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF439462),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (hasDelivery)
                Text('${deliveringSubs.length + ordersForDate.length} item(s)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasDelivery)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No deliveries scheduled for this day.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else ...[
            // Show matched/real orders first
            ...ordersForDate.map((order) {
              final items = order['items'] as List<dynamic>? ?? [];
              if (items.isEmpty) return const SizedBox();
              return _buildRealOrderItem(order);
            }),
            // Show subscriptions that haven't turned into orders yet
            ...deliveringSubs.where((sub) {
              // Avoid duplicates if order is already shown
              return !ordersForDate.any((o) {
                final oItems = o['items'] as List<dynamic>? ?? [];
                return oItems.any((item) =>
                    item['product']?['_id'] == sub.productId ||
                    item['product'] == sub.productId);
              });
            }).map((sub) => _buildDeliveryItem(sub)),
          ],
        ],
      ),
    );
  }

  Widget _buildRealOrderItem(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox();
    final item = items.first;
    final product = item['product'];
    final name =
        product is Map ? product['name']?.toString() ?? 'Item' : 'Item';
    final image =
        (product is Map && (product['images'] as List?)?.isNotEmpty == true)
            ? (product['images'] as List).first.toString()
            : '';
    final qty = item['quantity']?.toString() ?? '1';
    final status = order['status']?.toString() ?? 'Pending';
    final isDelivered = status.toLowerCase() == 'delivered';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image.isNotEmpty
                ? Image.network(image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder)
                : _imagePlaceholder,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Qty $qty • Real-time Status: $status',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderTrackingPage(order: order),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: Color(0xFF68B92E), size: 16),
                SizedBox(width: 4),
                Text(
                  'Track',
                  style: TextStyle(
                    color: Color(0xFF68B92E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF68B92E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(isDelivered ? Icons.check_circle : Icons.radio_button_checked,
              color: const Color(0xFF68B92E)),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(UserSubscription sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: sub.productImage.isNotEmpty
                ? Image.network(sub.productImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder)
                : _imagePlaceholder,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (sub.retailerName.isNotEmpty)
                  Text(sub.retailerName,
                      style: TextStyle(
                          color: const Color(0xFF114F3B).withValues(alpha: 0.1),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                Text('Qty ${sub.quantity} • ${sub.frequency}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openTrackingForSubscription(sub),
            child: const Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: Color(0xFF68B92E), size: 16),
                SizedBox(width: 4),
                Text(
                  'Track',
                  style: TextStyle(
                    color: Color(0xFF68B92E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF68B92E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.check_circle, color: Color(0xFF68B92E)),
        ],
      ),
    );
  }

  /// Fetches the latest order for [sub] from the backend and navigates
  /// to [OrderTrackingPage] with the real order data.
  Future<void> _openTrackingForSubscription(UserSubscription sub) async {
    if (!mounted) return;
    
    // Show a loading dialog instead of snackbar (which causes deactivated widget state crashes)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))),
    );

    try {
      final orderService = ref.read(orderServiceProvider);
      Map<String, dynamic> order = await orderService.getOrderBySubscriptionId(sub.id);

      // If no backend order found, use a sensible stub so the page still opens
      if (order.isEmpty) {
        order = {
          '_id': sub.id,
          'orderId': sub.id,
          'status': 'Processing',
          'orderType': 'Subscription',
          'frequency': sub.frequency,
          'customDays': sub.customDays,
          'items': [
            {
              'quantity': sub.quantity,
              'price': 0,
              'product': {
                'name': sub.productName,
                'images': [sub.productImage],
              },
            }
          ],
        };
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingPage(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget get _imagePlaceholder => Container(
        width: 50,
        height: 50,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.set_meal, color: Color(0xFF68B92E), size: 24),
      );

  Widget _buildYourPlans(List<UserSubscription> subs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Plans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        if (subs.isEmpty)
          const Text('No active plans. Subscribe to a product to get started!',
              style: TextStyle(color: Colors.grey))
        else
          ...subs.map((sub) => _PlanItemWidget(sub: sub)),
      ],
    );
  }

  Widget _buildQuickActions(List<UserSubscription> subs) {
    final isVacationOn = subs.isNotEmpty && subs.every((s) => s.status == 'Paused');

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.flight_takeoff,
            label: isVacationOn ? 'Vacation: ON' : 'Vacation: OFF',
            color: isVacationOn ? Colors.orange : Colors.grey.shade700,
            onTap: subs.isEmpty
                ? null
                : () => _toggleVacationMode(subs, isVacationOn),
          ),
        ),
      ],
    );
  }

  Widget _buildVacationNote() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Note: Vacations for tomorrow must be set before 8:00 PM. '
              'Changes after 8:00 PM will apply from the day after tomorrow.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCutOffAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Too Late to Pause'),
        content: const Text(
          'Orders for tomorrow are already being processed (Cut-off was 8:00 PM). '
          'You can only set vacations for the day after tomorrow.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _toggleVacationMode(List<UserSubscription> subs, bool wasOn) async {
    final subService = ref.read(subscriptionServiceProvider);

    if (wasOn) {
      // Resume logic
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume Deliveries?'),
          content: const Text('All your paused subscriptions will be resumed starting from tomorrow.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Resume Now', style: TextStyle(color: Color(0xFF68B92E)))),
          ],
        ),
      );
      if (confirm != true) return;

      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));
      
      try {
        final pausedSubs = subs.where((s) => s.status == 'Paused').toList();
        await Future.wait(pausedSubs.map((s) => subService.updateStatus(s.id, 'Active')));
        ref.invalidate(mySubscriptionsProvider);
        await ref.read(mySubscriptionsProvider.future);
        if (mounted) Navigator.pop(context);
      } catch (_) { if (mounted) Navigator.pop(context); }

    } else {
      // Pause logic with cut-off check
      if (AppDateUtils.isPastCutOff()) {
        _showCutOffAlert();
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activate Vacation Mode?'),
          content: const Text('This will pause all your deliveries indefinitely starting from tomorrow.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pause All', style: TextStyle(color: Colors.orange))),
          ],
        ),
      );
      if (confirm != true) return;

      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));
      
      try {
        final activeSubs = subs.where((s) => s.status == 'Active').toList();
        await Future.wait(activeSubs.map((s) => subService.updateStatus(s.id, 'Paused')));
        ref.invalidate(mySubscriptionsProvider);
        await ref.read(mySubscriptionsProvider.future);
        if (mounted) Navigator.pop(context);
      } catch (_) { if (mounted) Navigator.pop(context); }
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap == null ? Colors.grey : color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? Colors.grey : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PlanItemWidget extends ConsumerStatefulWidget {
  final UserSubscription sub;

  const _PlanItemWidget({required this.sub});

  @override
  ConsumerState<_PlanItemWidget> createState() => _PlanItemWidgetState();
}

class _PlanItemWidgetState extends ConsumerState<_PlanItemWidget> {
  bool? _optimisticIsActive;

  @override
  void didUpdateWidget(covariant _PlanItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sub.status != widget.sub.status) {
      // Clear optimistic state when actual state arrives
      _optimisticIsActive = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _optimisticIsActive ?? (widget.sub.status == 'Active');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isActive ? const Color(0xFF68B92E) : Colors.grey)
                .withValues(alpha: 0.12),
            child: Icon(isActive ? Icons.check : Icons.pause,
                color: isActive ? const Color(0xFF68B92E) : Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.sub.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.sub.frequency,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          // Pause / Resume toggle
          Switch(
            value: isActive,
            activeThumbColor: const Color(0xFF68B92E),
            onChanged: (val) async {
              // Optimistic UI update
              setState(() {
                _optimisticIsActive = val;
              });

              final messenger = ScaffoldMessenger.of(context);
              final newStatus = val ? 'Active' : 'Paused';
              final ok = await ref
                  .read(subscriptionServiceProvider)
                  .updateStatus(widget.sub.id, newStatus);

              if (ok) {
                ref.invalidate(mySubscriptionsProvider);
              } else {
                // Revert optimistic update on failure
                if (mounted) {
                  setState(() {
                    _optimisticIsActive = null;
                  });
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update plan status'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
