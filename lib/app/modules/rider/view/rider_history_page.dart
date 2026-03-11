import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/services/rider_service.dart';
import '../../../core/constants/app_colors.dart';

final riderHistoryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final riderService = ref.watch(riderServiceProvider);
  return riderService.getOrderHistory();
});

class RiderHistoryPage extends ConsumerWidget {
  final bool isTab;
  const RiderHistoryPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(riderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Delivery History',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1A1A1A), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(riderHistoryProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentGreen,
        onRefresh: () async => ref.invalidate(riderHistoryProvider),
        child: historyAsync.when(
          data: (history) {
            final sortedHistory = List<dynamic>.from(history);
            sortedHistory.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
              final dateB =
                  DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
              return dateB.compareTo(dateA); // Newest first
            });

            if (sortedHistory.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedHistory.length,
              itemBuilder: (context, index) {
                final order = sortedHistory[index];
                return _buildHistoryCard(order);
              },
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen)),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order['orderId'].toString().substring(order['orderId'].toString().length - 6).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBFFD7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['status'] ?? 'Delivered',
                        style: const TextStyle(
                          color: Color(0xFF68B92E),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
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
                      order['dateTime'] ?? '',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.person_outline_rounded, 'Customer',
                    order['customerName'] ?? 'Unnamed'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, 'Phone Number',
                    order['phoneNumber'] ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, 'Address',
                    _formatAddress(order['address'])),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.shopping_bag_outlined, 'Items',
                    _formatItems(order['items'])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${order['totalAmount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatAddress(dynamic addr) {
    if (addr == null || addr is! Map) return 'No address';
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
    return items.map((e) => '${e['name']} (x${e['quantity']})').join(', ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed deliveries will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
