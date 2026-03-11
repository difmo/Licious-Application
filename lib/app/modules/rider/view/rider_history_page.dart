import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rider_service.dart';
import 'package:intl/intl.dart';

final deliveryHistoryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final all = await ref.read(riderServiceProvider).getDeliveryHistory();
  // Show only delivered / completed orders
  return all.where((o) {
    final s = (o['status']?.toString() ?? '').toLowerCase();
    return s == 'delivered' || s == 'completed';
  }).toList();
});

class RiderHistoryPage extends ConsumerWidget {
  const RiderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deliveryHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4EC),
      appBar: AppBar(
        title: const Text('Delivery History',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF114F3B))),
        backgroundColor: const Color(0xFFF0F4EC),
        foregroundColor: const Color(0xFF114F3B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF114F3B)),
            onPressed: () => ref.invalidate(deliveryHistoryProvider),
          )
        ],
      ),
      body: historyAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            color: AppColors.accentGreen,
            onRefresh: () async => ref.invalidate(deliveryHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: deliveries.length,
              itemBuilder: (context, index) =>
                  _DeliveryHistoryCard(item: deliveries[index]),
            ),
          );
        },
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Could not load history',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(deliveryHistoryProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 52, color: AppColors.accentGreen),
          ),
          const SizedBox(height: 20),
          const Text('No Deliveries Yet',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF114F3B))),
          const SizedBox(height: 8),
          Text('Completed deliveries will appear here',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── History Card ────────────────────────────────────────────────────────────

class _DeliveryHistoryCard extends StatelessWidget {
  final dynamic item;
  const _DeliveryHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // ── Order ID ─────────────────────────────────────────────────────────────
    final String rawId =
        (item['orderId'] ?? item['_id'] ?? item['id'] ?? '').toString();
    final String shortId = rawId.length > 8
        ? rawId.substring(rawId.length - 8).toUpperCase()
        : rawId.toUpperCase();

    // ── Date ────────────────────────────────────────────────────────────────
    String displayDate = '';
    final ds = item['deliveredAt']?.toString() ??
        item['updatedAt']?.toString() ??
        item['createdAt']?.toString() ??
        '';
    if (ds.isNotEmpty) {
      try {
        displayDate = DateFormat('MMM dd, yyyy  •  hh:mm a')
            .format(DateTime.parse(ds).toLocal());
      } catch (_) {
        displayDate = ds;
      }
    }

    // ── Customer ─────────────────────────────────────────────────────────────
    final userData = item['user'] ?? item['customer'];
    final String customerName = userData is Map
        ? (userData['fullName'] ?? userData['name'] ?? 'Customer')
        : (item['customerName']?.toString() ?? 'Customer');
    final String customerPhone = userData is Map
        ? (userData['phoneNumber'] ?? userData['phone'] ?? '')
        : (item['phoneNumber']?.toString() ?? '');

    // ── Address ──────────────────────────────────────────────────────────────
    String addressStr = 'Address not available';
    final addrRaw = item['deliveryAddress'] ?? item['address'];
    if (addrRaw is Map) {
      addressStr = addrRaw['fullAddress']?.toString() ??
          addrRaw['address']?.toString() ??
          'Address details unavailable';
    } else if (addrRaw is String && addrRaw.isNotEmpty) {
      addressStr = addrRaw;
    }

    // ── Items ────────────────────────────────────────────────────────────────
    final itemsList = item['items'] as List<dynamic>? ?? [];
    final String itemsSummary = itemsList.isNotEmpty
        ? itemsList.map((i) {
            final n = i['name']?.toString() ??
                (i['product'] is Map ? i['product']['name']?.toString() : null) ??
                'Item';
            return '${i['quantity'] ?? 1}x $n';
          }).join(', ')
        : 'No items info';

    // ── Financials ───────────────────────────────────────────────────────────
    final double total =
        (item['totalAmount'] ?? item['grandTotal'] ?? item['total'] ?? 0)
            .toDouble();
    final String paymentMethod =
        item['paymentMethod']?.toString() ?? 'Cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Green header ── ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF114F3B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #$shortId',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                    if (displayDate.isNotEmpty)
                      Text(displayDate,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.greenAccent, size: 12),
                      SizedBox(width: 4),
                      Text('DELIVERED',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Customer
                _Row(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: customerName +
                      (customerPhone.isNotEmpty ? '  ·  $customerPhone' : ''),
                ),
                const SizedBox(height: 10),
                // Address
                _Row(
                  icon: Icons.location_on_outlined,
                  label: 'Delivered to',
                  value: addressStr,
                ),
                const SizedBox(height: 10),
                // Items
                _Row(
                  icon: Icons.set_meal_outlined,
                  label: 'Items',
                  value: itemsSummary,
                  maxLines: 2,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Colors.grey.shade100, thickness: 1.5),
                ),
                // Financials row
                Row(
                  children: [
                    // Payment method chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            paymentMethod.toLowerCase().contains('wallet')
                                ? Icons.account_balance_wallet_outlined
                                : Icons.payments_outlined,
                            size: 13,
                            color: const Color(0xFF114F3B),
                          ),
                          const SizedBox(width: 5),
                          Text(paymentMethod,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF114F3B))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppColors.accentGreen),
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
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4EC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF114F3B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
