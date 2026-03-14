import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/services/subscription_service.dart';
import '../../../data/services/order_service.dart';
import '../../../core/constants/app_colors.dart';

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
      body: subscriptionsAsync.when(
        data: (subscriptions) => subscriptions.isEmpty
            ? _buildEmptyState(context)
            : _buildSubscriptionList(context, ref, subscriptions),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
      padding: const EdgeInsets.all(16),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        return _buildSubscriptionCard(context, ref, sub);
      },
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
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.accentGreen,
                  onChanged: (val) async {
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
                    if (isActive)
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
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
      final res = await ref.read(subscriptionServiceProvider).updateVacation(
            subscriptionId: sub.id,
            startDate: picked.start,
            endDate: picked.end,
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
}
