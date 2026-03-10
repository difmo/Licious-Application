import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rider_service.dart';
import 'package:intl/intl.dart';

final deliveryHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(riderServiceProvider).getDeliveryHistory();
});

class RiderHistoryPage extends ConsumerWidget {
  const RiderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deliveryHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Delivery History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: historyAsync.when(
        data: (deliveries) {
          if (deliveries.isEmpty) {
            return const Center(child: Text('No past deliveries', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final item = deliveries[index];
              
              // Handle Date
              String displayDate = '';
              if (item['dateTime'] != null) {
                displayDate = item['dateTime'].toString();
              } else {
                final ds = item['createdAt']?.toString() ?? DateTime.now().toIso8601String();
                try {
                  displayDate = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(ds).toLocal());
                } catch (_) {
                  displayDate = ds;
                }
              }
              
              final String orderId = (item['orderId'] ?? item['_id'] ?? item['id'] ?? '').toString().toUpperCase();
              
              // Customer Details
              final String customerName = item['customerName']?.toString() ?? 'Customer';
              final String customerPhone = item['phoneNumber']?.toString() ?? 'N/A';
              
              // Address
              String addressStr = 'Address not found';
              if (item['address'] is String) {
                addressStr = item['address'];
              } else if (item['address'] is Map) {
                final aMap = item['address'] as Map;
                addressStr = aMap['fullAddress'] ?? aMap['address'] ?? 'Address details not provided (coordinates only)';
              } else if (item['deliveryAddress'] is Map) {
                final dMap = item['deliveryAddress'] as Map;
                addressStr = dMap['fullAddress'] ?? dMap['address'] ?? 'Address not found';
              }
              
              // Items
              final itemsList = item['items'] as List<dynamic>? ?? [];
              String itemsDesc = itemsList.map((i) {
                final name = i['name']?.toString() ?? (i['product'] is Map ? i['product']['name']?.toString() : null) ?? 'Item';
                return '${i['quantity'] ?? 1}x $name (₹${i['price'] ?? 0})';
              }).join(', ');
              if (itemsDesc.isEmpty) itemsDesc = 'No items found';

              // Payment and totals
              final paymentMethod = item['paymentMethod']?.toString() ?? 'COD';
              final total = (item['totalAmount'] ?? item['total'] ?? item['earnings'] ?? 0).toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Order #$orderId',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEBFFD7), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            item['status']?.toString() ?? 'Delivered', 
                            style: const TextStyle(color: AppColors.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(displayDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const Divider(height: 24),
                    
                    _InfoRow(icon: Icons.person, title: customerName, subtitle: customerPhone),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.location_on, title: 'Delivery Address', subtitle: addressStr),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.shopping_bag, title: 'Items', subtitle: itemsDesc),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.payment, title: 'Payment Method', subtitle: paymentMethod),
                    
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹$total', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
