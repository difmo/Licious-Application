import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/services/subscription_service.dart';
import '../../../data/services/order_service.dart';
import '../../orders/view/order_tracking_page.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';

class SubscriptionDashboardPage extends ConsumerWidget {
  const SubscriptionDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('My Subscriptions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.accentGreen,
        onRefresh: () async {
          ref.invalidate(mySubscriptionsProvider);
          try {
            await ref.read(mySubscriptionsProvider.future);
          } catch (_) {}
        },
        child: subscriptionsAsync.when(
          data: (subscriptions) => subscriptions.isEmpty
              ? Stack(
                  children: [
                    ListView(physics: const AlwaysScrollableScrollPhysics()), // Allows pull-to-refresh
                    _buildEmptyState(context),
                  ],
                )
              : _buildSubscriptionList(context, ref, subscriptions),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen)),
          error: (err, stack) => Stack(
            children: [
              ListView(physics: const AlwaysScrollableScrollPhysics()),
              Center(child: Text('Error: $err')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No active subscriptions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Subscribe to your favorite products to see them here!',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(BuildContext context, WidgetRef ref,
      List<UserSubscription> subscriptions) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: subscriptions.length + 1,
      itemBuilder: (context, index) {
        if (index == subscriptions.length) {
          return _buildVacationNote();
        }
        final sub = subscriptions[index];
        return _buildSubscriptionCard(context, ref, sub);
      },
    );
  }

  Widget _buildVacationNote() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 20, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Text(
                'Vacation & Scheduling Rules',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleRow('Vacation ON: ', 'Pauses your deliveries while away.'),
          _buildRuleRow('Vacation OFF: ', 'Normal deliveries resume as scheduled.'),
          const SizedBox(height: 12),
          Text(
            '⏰ The 8:00 PM Cut-off Rule',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
          ),
          const SizedBox(height: 6),
          Text(
            '• Before 8:00 PM: Changes apply from TOMORROW\n'
            '• After 8:00 PM: Changes apply from DAY AFTER TOMORROW\n\n'
            'Why? By 8 PM, preparation and inventory checks for the next day begin to ensure maximum freshness!',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            '📊 Examples:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
          ),
          const SizedBox(height: 6),
          Text(
            'Example A (Morning): "It\'s 10:00 AM on Monday. I set Vacation to ON. My Tuesday delivery will be paused."\n\n'
            'Example B (Late Night): "It\'s 9:30 PM on Monday. I set Vacation to ON. My Tuesday delivery is already prepped, so it will still arrive. My vacation will start from Wednesday."',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
          children: [
            TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
      BuildContext context, WidgetRef ref, UserSubscription sub) {
    final bool isActive = sub.status == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: sub.productImage.isNotEmpty
                      ? Image.asset(sub.productImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.shopping_basket)))
                      : Container(
                          color: Colors.grey.shade100,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.shopping_basket)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${sub.frequency} • Qty: ${sub.quantity}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                      if (!isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200)
                            ),
                            child: Text('🏖️ Vacation ON', 
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.accentGreen,
                  onChanged: (val) async {
                    if (!val && AppDateUtils.isPastCutOff()) {
                      _showCutOffAlert(context);
                      return;
                    }

                    if (val && !isActive) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Vacation Mode ON', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text(
                            'Your subscription is currently paused on Vacation Mode. Please turn off your vacation mode by tapping "Manage" to resume deliveries.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      // Return immediately so the switch does not activate
                      return;
                    }

                    final newStatus = val ? 'Active' : 'Paused';
                    final success = await ref
                        .read(subscriptionServiceProvider)
                        .updateStatus(sub.id, newStatus);
                    if (success) {
                      ref.invalidate(mySubscriptionsProvider);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next Delivery',
                          style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        isActive ? "Tomorrow, 7:00 AM" : "Paused",
                        style: TextStyle(
                          color: isActive ? AppColors.accentGreen : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      _TrackDeliveryButton(subscriptionId: sub.id),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => _placeSpotOrder(context, ref, sub),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange.shade900,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Deliver Today',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _showVacationPicker(context, ref, sub),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Manage'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeSpotOrder(
      BuildContext context, WidgetRef ref, UserSubscription sub) async {
    // Logic to place a one-time order for today
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deliver Today?'),
        content: Text(
            'Would you like an extra delivery of ${sub.productName} today?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Order')),
        ],
      ),
    );

    if (success == true) {
      // For now, using default address and wallet as payment
      // In a real app, you might want to confirm these
      final res = await ref.read(orderServiceProvider).placeSpotOrder(
        deliveryAddress: {}, // Backend should handle if empty or use user default
        paymentMethod: 'Wallet',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Spot order placed successfully'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ));
      }
    }
  }

  void _showVacationPicker(
      BuildContext context, WidgetRef ref, UserSubscription sub) async {
    final firstDate = AppDateUtils.getFirstAllowedDate();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Task 3: Check if they picked tomorrow but it's past cut-off
      final isTomorrowPicked = AppDateUtils.formatDate(picked.start) ==
          AppDateUtils.formatDate(firstDate);
      if (isTomorrowPicked && AppDateUtils.isPastCutOff()) {
        if (context.mounted) _showCutOffAlert(context);
        return;
      }

      final dates = AppDateUtils.getDatesBetween(picked.start, picked.end);
      final res = await ref.read(subscriptionServiceProvider).updateVacation(
            subscriptionId: sub.id,
            vacationDates: dates,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Vacation updated'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ));
        if (res['success'] == true) {
          ref.invalidate(mySubscriptionsProvider);
        }
      }
    }
  }

  void _showCutOffAlert(BuildContext context) {
    if (!context.mounted) return;
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
}

class _TrackDeliveryButton extends ConsumerWidget {
  final String subscriptionId;

  const _TrackDeliveryButton({required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This value is cached by FutureProvider.family, so it's efficient to watch.
    final orderAsync = ref.watch(orderBySubscriptionProvider(subscriptionId));

    return orderAsync.maybeWhen(
      data: (order) {
        if (order.isEmpty) return const SizedBox.shrink();

        final status = (order['status'] ?? '').toString().toLowerCase();
        // Don't show tracking for finished or non-existent orders
        if (status == 'delivered' || status == 'cancelled' || status.isEmpty) {
          return const SizedBox.shrink();
        }

        return ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderTrackingPage(order: order),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8F5E9),
            foregroundColor: const Color(0xFF1B5E20),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.location_searching, size: 14),
              SizedBox(width: 4),
              Text('Track',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
