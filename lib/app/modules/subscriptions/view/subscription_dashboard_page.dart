import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:licius_application/app/data/models/subscription_model.dart';
import 'package:licius_application/app/data/services/subscription_service.dart';
import 'package:licius_application/app/data/services/order_service.dart';
import '../../orders/view/order_tracking_page.dart';
import 'package:licius_application/app/core/constants/app_colors.dart';
import 'package:licius_application/app/core/utils/date_utils.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

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
          loading: () => Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
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
    // Filter out cancelled subscriptions
    final activeOrPausedSubs = subscriptions.where((s) {
      final status = s.status.toLowerCase();
      return status == 'active' || status == 'paused';
    }).toList();

    if (activeOrPausedSubs.isEmpty) {
      return Stack(
        children: [
          ListView(physics: const AlwaysScrollableScrollPhysics()),
          _buildEmptyState(context),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: activeOrPausedSubs.length + 1,
      itemBuilder: (context, index) {
        if (index == activeOrPausedSubs.length) {
          return _buildVacationNote();
        }
        final sub = activeOrPausedSubs[index];
        return _SubscriptionCard(sub: sub);
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
}

class _SubscriptionCard extends ConsumerStatefulWidget {
  final UserSubscription sub;

  const _SubscriptionCard({required this.sub});

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _isCancelled = false;

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) return const SizedBox.shrink();

    final sub = widget.sub;
    final bool isActive = sub.status == 'Active';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Slidable(
        key: ValueKey(sub.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Subscription?'),
                    content: const Text('Are you sure you want to completely cancel this subscription?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm == true) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
                  );
                  
                  final success = await ref.read(subscriptionServiceProvider).cancelSubscription(sub.id);
                  if (mounted) Navigator.pop(context);

                  if (success) {
                    setState(() => _isCancelled = true);
                    ref.invalidate(mySubscriptionsProvider);
                  }
                }
              },
              backgroundColor: const Color(0xFFFE4A49),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Cancel',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: Container(
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
                          ? Image.network(sub.productImage,
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
                          Text(
                              '${sub.productName}${sub.weightLabel != null && sub.weightLabel!.isNotEmpty ? " (${sub.weightLabel})" : ""}',
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
                      activeColor: AppColors.accentGreen,
                      activeTrackColor: AppColors.accentGreen.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade200,
                      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        return states.contains(WidgetState.selected) 
                          ? AppColors.accentGreen.withValues(alpha: 0.5) 
                          : Colors.grey.shade300;
                      }),
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
                              title: const Text('🏖️ Vacation Mode is ON', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text(
                                'Your subscription is currently paused. Please go to Daily Deliveries and turn off Vacation Mode to resume your deliveries.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Delivery',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          isActive ? 'Tomorrow' : 'Paused',
                          style: TextStyle(
                            color: isActive ? AppColors.accentGreen : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (isActive) _TrackDeliveryButton(subscriptionId: sub.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCutOffAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Too Late to Pause'),
        content: const Text(
          'Orders for tomorrow are already being processed (Cut-off was 8:00 PM). '
          'You can only set vacations for the day after tomorrow.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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

