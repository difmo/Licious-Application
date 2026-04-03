import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/subscription_service.dart';
import '../../data/services/order_service.dart';
import '../../data/services/db_service.dart';
import '../../core/utils/date_utils.dart';
import '../orders/view/order_tracking_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../routes/app_routes.dart';
import '../../../../core/utils/logger.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _startDate;
  bool? _optimisticVacationState;

  @override
  void initState() {
    super.initState();
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
              // Header with vacation toggle embedded
              subscriptionsAsync.when(
                data: (subs) => Column(
                  children: [
                    _buildHeader(balance, subs),
                    _buildHorizontalCalendar(subs),
                  ],
                ),
                loading: () => Column(
                  children: [
                    _buildHeader(balance, []),
                    _buildHorizontalCalendar([]),
                  ],
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              Expanded(
                child: subscriptionsAsync.when(
                  data: (subs) => ordersAsync.when(
                    data: (orders) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildVacationButton(subs),
                              const SizedBox(width: 10),
                              _buildPauseTomorrowButton(subs),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusCard(subs, orders),
                          const SizedBox(height: 20),
                          _buildYourPlans(subs),
                          const SizedBox(height: 20),
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

  Widget _buildHeader(double balance, List<UserSubscription> subs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Wallet Balance
          Row(
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
                        style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar(List<UserSubscription> subs) {
    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = _startDate.add(Duration(days: index));
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          
          final activeOrPausedSubsDay = subs.where((s) {
            final st = s.status.toLowerCase();
            return st == 'active' || st == 'paused';
          }).toList();
          
          final hasDelivery = activeOrPausedSubsDay.any((s) => s.status.toLowerCase() == 'active' && _deliversOn(s, date));
          // Calculate state for this specific day
          final isGlobalVacation = activeOrPausedSubsDay.isNotEmpty && !activeOrPausedSubsDay.any((s) => s.status.toLowerCase() == 'active');
          final isOptimisticVacation = _optimisticVacationState ?? isGlobalVacation;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF68B92E) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFF68B92E), width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Showing Green Dot for delivery OR Umbrella icon for vacation
                  Builder(builder: (context) {
                    final nowStr = AppDateUtils.formatDate(DateTime.now());
                    final dateStr = AppDateUtils.formatDate(date);
                    final isPastDate = date.isBefore(DateTime.now()) && nowStr != dateStr;

                    if (isPastDate) return const SizedBox(height: 12);

                    final deliversToday = subs.any((s) => s.status.toLowerCase() == 'active' && _deliversOn(s, date));
                    final isSkipped = subs.any((s) => 
                        s.vacationDates.any((vd) => AppDateUtils.isSameDay(vd, date)));
                    final globallyPaused = subs.isNotEmpty && subs.every((s) => s.status.toLowerCase() == 'paused');

                    // Creative State: Paused or Skipped (Vacation Theme)
                    if (isSkipped || globallyPaused) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '🏖️', 
                          style: TextStyle(fontSize: 10, shadows: [
                            Shadow(color: Colors.amber, blurRadius: 4, offset: Offset(0, 1))
                          ]),
                        ),
                      );
                    } 
                    
                    // Standard State: Active Delivery
                    if (deliversToday && !isOptimisticVacation) {
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF68B92E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF68B92E).withValues(alpha: 0.4), blurRadius: 2, offset: const Offset(0, 1))
                          ],
                        ),
                      );
                    }
                    return const SizedBox(height: 12);
                  }),
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
    // Rule: Only show as 'Scheduled' if the date is effective (Next allowed date after resume/pause)
    final firstAllowed = AppDateUtils.getFirstAllowedDate();
    final isEffectiveDate = _selectedDate.isAtSameMomentAs(firstAllowed) || 
                            _selectedDate.isAfter(firstAllowed);

    final deliveringSubs = subs.where((s) {
      final deliversOnDay = s.status == 'Active' && _deliversOn(s, _selectedDate);
      // Logic: Only show the "Plan" as active if we are past the cut-off for today
      // This prevents "Today" showing as Scheduled immediately after resuming Vacation at 10 AM.
      return deliversOnDay && isEffectiveDate;
    }).toList();

    // 1.5 Find subscriptions specifically SKIPPED for this date (Vacation)
    final skippedSubs = subs.where((s) => 
        s.status.toLowerCase() == 'paused' || 
        s.vacationDates.any((vd) => AppDateUtils.isSameDay(vd, _selectedDate))).toList();

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
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF439462),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (hasDelivery)
                Text(
                  '${deliveringSubs.length + ordersForDate.length} item(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (deliveringSubs.isEmpty && ordersForDate.isEmpty && skippedSubs.isNotEmpty)
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text('🏖️', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 8),
                      Text('ON VACATION', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                ...skippedSubs.map((sub) => _buildDeliveryItem(sub, isPaused: true)),
              ],
            ),
          
          if (!hasDelivery && skippedSubs.isEmpty)
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

    final weightLabel = (item['weightLabel'] ?? item['weight_label'] ?? '').toString();
    final displayName = '$name${weightLabel.isNotEmpty ? " ($weightLabel)" : ""}';

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
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDeliveryItem(UserSubscription sub, {bool isPaused = false}) {
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
                Text(
                  '${sub.productName}${sub.weightLabel != null && sub.weightLabel!.isNotEmpty ? " (${sub.weightLabel})" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              isPaused ? 'VACATION' : 'PENDING',
              style: TextStyle(
                  color: isPaused ? Colors.amber : Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _imagePlaceholder => Container(
        width: 50,
        height: 50,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.set_meal, color: Color(0xFF68B92E), size: 24),
      );

  Widget _buildYourPlans(List<UserSubscription> subs) {
    if (subs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text('No active plans yet. Start a delivery today!', 
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      );
    }

    // Only show Active and Paused in the main "Your Plans" list
    final activeOrPausedSubs = subs.where((s) {
      final st = s.status.toLowerCase();
      return st == 'active' || st == 'paused';
    }).toList();
    
    // Globally determine if vacation is ON for the purpose of blocking individual switches
    final isVacationOn = activeOrPausedSubs.isNotEmpty && activeOrPausedSubs.every((s) => s.status.toLowerCase() == 'paused');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Plans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.mySubscriptions),
              child: const Text('View All →',
                  style: TextStyle(
                      color: Color(0xFF68B92E),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Group Active & Paused first
        ...activeOrPausedSubs.map((sub) => _PlanItemWidget(sub: sub, isVacationOn: isVacationOn)),
      ],
    );
  }



  void _toggleVacationMode(List<UserSubscription> subs, bool wasOn) async {
    final subService = ref.read(subscriptionServiceProvider);
    final isPast8PM = AppDateUtils.isPastCutOff();
    
    AppLogger.i('--- Vacation Mode Toggle Triggered ---');
    AppLogger.d('Current Visual State (wasOn): $wasOn');
    AppLogger.d('Total Subscriptions: ${subs.length}');
    AppLogger.d('Current Hour: ${DateTime.now().hour}, isPast8PM: $isPast8PM');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${wasOn ? 'Resume' : 'Pause'} Deliveries?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(wasOn
            ? 'All your paused subscriptions will be resumed starting from tomorrow.'
            : isPast8PM
                ? 'It\'s past 8:00 PM (retailer cut-off). Tomorrow\'s orders are already processing.\n\nActivate Vacation Mode starting from the DAY AFTER TOMORROW?'
                : 'This will pause all your deliveries indefinitely starting from tomorrow.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(wasOn ? 'Resume Now' : 'Pause All',
                style: TextStyle(color: wasOn ? const Color(0xFF68B92E) : Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    
    // Optimistic Update: Change toggle immediately
    setState(() => _optimisticVacationState = !wasOn);
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));
    
    try {
      final targetStatus = wasOn ? 'Active' : 'Paused';
      
      final success = await subService.updateAllStatus(targetStatus);
      AppLogger.i('API Call Success: $success');

      if (!success) {
         throw Exception('Bulk update failed on server');
      }
      
      ref.invalidate(mySubscriptionsProvider);
      await ref.read(mySubscriptionsProvider.future);
      AppLogger.d('Provider Invalidation Complete');

      if (mounted) {
        setState(() => _optimisticVacationState = null);
        Navigator.pop(context); // Close loading
      }
    } catch (e) {
      AppLogger.e('Vacation Toggle Failed: $e');
      if (mounted) {
        setState(() => _optimisticVacationState = null);
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildPauseTomorrowButton(List<UserSubscription> subs) {
    if (subs.isEmpty) return const SizedBox.shrink();

    // Hide this button if a VACATION range is active (to keep UI independent as requested)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isVacationActive = subs.any((s) => s.vacationDates.any((d) => !d.isBefore(today)));
    if (isVacationActive) return const SizedBox.shrink();

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = AppDateUtils.formatDate(tomorrow);
    final isPast8PM = AppDateUtils.isPastCutOff();

    // Check if everything is already paused (Global Vacation) or if tomorrow is already skipped
    final isTomorrowAlreadyPaused = subs.every((s) =>
        s.status.toLowerCase() == 'paused' ||
        s.vacationDates.any((d) => AppDateUtils.isSameDay(d, tomorrow)));

    // State: Already Paused or Generally Vacation is ON (Allows UNDO/RESUME)
    if (isTomorrowAlreadyPaused) {
      return GestureDetector(
        onTap: () => _resumeTomorrowBulkSkip(subs),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0), // Light Amber
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_fill, size: 14, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Resume Tomorrow',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFFE65100), // Dark Orange
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.undo, size: 10, color: Colors.orange),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (isPast8PM) {
          _showPast8PMAlert(context);
          return;
        }
        _pauseTomorrowBulkSkip(subs);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPast8PM ? Colors.grey.shade100 : const Color(0xFFEBFFD7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isPast8PM
                  ? Colors.grey.shade300
                  : const Color(0xFF68B92E).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_filled,
              size: 14,
              color: isPast8PM ? Colors.grey : const Color(0xFF68B92E),
            ),
            const SizedBox(width: 6),
            Text(
              'Pause Tomorrow',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isPast8PM ? Colors.grey : const Color(0xFF2E7D32),
              ),
            ),
            if (!isPast8PM) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: const Color(0xFF68B92E),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPast8PMAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🕗 Past 8:00 PM', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('It is too late to pause deliveries for tomorrow. Please use Vacation Mode to pause from the day after tomorrow.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF68B92E), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _pauseTomorrowBulkSkip(List<UserSubscription> subs) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = AppDateUtils.formatDate(tomorrow);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Skip Tomorrow?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('This will skip ALL your deliveries for ${DateFormat('EEEE, MMM d').format(tomorrow)}. They will automatically resume the day after.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip Tomorrow', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));

    try {
      final success = await ref.read(subscriptionServiceProvider).updateAllVacationDate([tomorrowStr], 'add');
      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        ref.invalidate(mySubscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully skipped tomorrow\'s deliveries.'), backgroundColor: Color(0xFF114F3B)),
        );
      } else {
        throw Exception('Server returned failure');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error skipping tomorrow: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resumeTomorrowBulkSkip(List<UserSubscription> subs) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = AppDateUtils.formatDate(tomorrow);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resume Tomorrow?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deliveries for ${DateFormat('EEEE, MMM d').format(tomorrow)} will be resumed. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Resume', style: TextStyle(color: Color(0xFF68B92E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));

    try {
      final success = await ref.read(subscriptionServiceProvider).updateAllVacationDate([tomorrowStr], 'remove');
      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        ref.invalidate(mySubscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully resumed tomorrow\'s deliveries.'), backgroundColor: Color(0xFF114F3B)),
        );
      } else {
        throw Exception('Server returned failure');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resuming tomorrow: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildVacationButton(List<UserSubscription> subs) {
    // Check if there are any vacation dates in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasFutureVacation = subs.any((s) => s.vacationDates.any((d) => !d.isBefore(today)));

    return GestureDetector(
      onTap: () => hasFutureVacation ? _handleStopVacation(subs) : _handleVacationSelection(subs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasFutureVacation ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasFutureVacation ? Colors.orange.withValues(alpha: 0.4) : const Color(0xFF68B92E).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasFutureVacation ? '🏝️ ' : '🏖️ ', style: const TextStyle(fontSize: 12)),
            Text(
              hasFutureVacation ? 'Stop Vacation' : 'Set Vacation',
              style: TextStyle(
                color: hasFutureVacation ? const Color(0xFFE65100) : const Color(0xFF114F3B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStopVacation(List<UserSubscription> subs) async {
    final firstAllowed = AppDateUtils.getFirstAllowedDate();
    
    // Find all future vacation dates that we can actually resume (must be >= firstAllowed)
    final allVacationDates = <DateTime>{};
    for (var s in subs) {
      allVacationDates.addAll(s.vacationDates);
    }
    
    final resumableDates = allVacationDates.where((d) => !d.isBefore(firstAllowed)).toList();
    
    if (resumableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No future vacation dates to stop. Any dates for tomorrow are already locked (Past 8 PM).')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Stop Vacation?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('This will resume your deliveries from ${AppDateUtils.formatDate(firstAllowed)}. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume Orders', style: TextStyle(color: Color(0xFF68B92E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));

      try {
        final dateStrings = resumableDates.map((d) => AppDateUtils.formatDate(d)).toList();
        final ok = await ref.read(subscriptionServiceProvider).updateAllVacationDate(dateStrings, 'remove');

        if (mounted) {
          Navigator.pop(context); 
          ref.invalidate(mySubscriptionsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vacation stopped. Deliveries will resume as scheduled.'), backgroundColor: Color(0xFF114F3B)),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stopping vacation: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleVacationSelection(List<UserSubscription> subs) async {
    final now = DateTime.now();
    final firstAllowed = AppDateUtils.getFirstAllowedDate();
    
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: firstAllowed, end: firstAllowed.add(const Duration(days: 3))),
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Vacation Dates',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF68B92E),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null && mounted) {
      // Calculate all dates between start and end
      final List<String> dates = [];
      DateTime current = range.start;
      while (!current.isAfter(range.end)) {
        dates.add(AppDateUtils.formatDate(current));
        current = current.add(const Duration(days: 1));
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Vacation', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('You are setting vacation for ${dates.length} days (${AppDateUtils.formatDate(range.start)} to ${AppDateUtils.formatDate(range.end)}). Deliveries will be skipped.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm', style: TextStyle(color: Color(0xFF68B92E), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))));

        try {
          final ok = await ref.read(subscriptionServiceProvider).updateAllVacationDate(dates, 'add');

          if (mounted) {
            Navigator.pop(context); 
            ref.invalidate(mySubscriptionsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully set vacation for ${dates.length} dates.'), backgroundColor: const Color(0xFF114F3B)),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); 
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error setting vacation: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }
}

class _PlanItemWidget extends ConsumerStatefulWidget {
  final UserSubscription sub;
  final bool isVacationOn;

  const _PlanItemWidget({required this.sub, this.isVacationOn = false});

  @override
  ConsumerState<_PlanItemWidget> createState() => _PlanItemWidgetState();
}

class _PlanItemWidgetState extends ConsumerState<_PlanItemWidget> {
  bool? _optimisticIsActive;
  bool _isCancelled = false; // Controls optimistic removal from list

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
    final status = widget.sub.status;
    final isCancelled = status == 'Cancelled';
    final isActive = _optimisticIsActive ?? (status == 'Active');
    final accentColor = isActive ? const Color(0xFF68B92E) : isCancelled ? Colors.red : Colors.orange;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isCancelled
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Slidable(
                key: ValueKey(widget.sub.id),
                endActionPane: isCancelled ? null : ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (slideContext) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Cancel Subscription?', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text('Are you sure you want to completely cancel this subscription? This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirm != true) return;
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF68B92E))),
                        );

                        final success = await ref.read(subscriptionServiceProvider).cancelSubscription(widget.sub.id);
                        if (!mounted) return;
                        Navigator.pop(context);

                        if (success) {
                          setState(() => _isCancelled = true);
                          ref.invalidate(mySubscriptionsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription cancelled successfully.'), backgroundColor: Color(0xFF114F3B)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to cancel subscription.'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      backgroundColor: const Color(0xFFFE4A49),
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outline,
                      label: 'Cancel',
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? const Color(0xFF68B92E).withValues(alpha: 0.15) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Product Thumbnail
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.sub.productImage.isNotEmpty
                            ? Image.network(
                                widget.sub.productImage,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.set_meal, color: Color(0xFF68B92E)),
                              )
                            : const Icon(Icons.set_meal, color: Color(0xFF68B92E)),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF68B92E).withValues(alpha: 0.1),
                                     borderRadius: BorderRadius.circular(6),
                                   ),
                                   child: Text('${widget.sub.quantity}x', 
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF68B92E))),
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     '${widget.sub.productName}${widget.sub.weightLabel != null && widget.sub.weightLabel!.isNotEmpty ? " (${widget.sub.weightLabel})" : ""}',
                                     style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2C3E50)),
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ],
                             ),
                            const SizedBox(height: 4),
                            if (widget.sub.retailerName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'By ${widget.sub.retailerName}',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Row(
                              children: [
                                Icon(Icons.repeat, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  widget.sub.frequency,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '₹${widget.sub.productPrice}',
                                  style: const TextStyle(color: Color(0xFF114F3B), fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (!isCancelled)
                        Column(
                          children: [
                            Switch(
                              value: isActive,
                              activeColor: const Color(0xFF68B92E),
                              activeTrackColor: const Color(0xFF68B92E).withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                              onChanged: (val) async {
                                if (widget.isVacationOn && val) {
                                  _showVacationBlocker(context);
                                  return;
                                }

                                setState(() {
                                  _optimisticIsActive = val;
                                });

                                final messenger = ScaffoldMessenger.of(context);
                                final newStatus = val ? 'Active' : 'Paused';
                                final ok = await ref.read(subscriptionServiceProvider).updateStatus(widget.sub.id, newStatus);

                                if (ok) {
                                  ref.invalidate(mySubscriptionsProvider);
                                } else {
                                  if (mounted) {
                                    setState(() {
                                      _optimisticIsActive = null;
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Failed to update plan status'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                            const Text('ENABLED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showVacationBlocker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🏖️ ', style: TextStyle(fontSize: 24)),
            Text('Vacation Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Please turn off Vacation Mode first to re-activate individual subscriptions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF68B92E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
