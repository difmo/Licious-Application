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
              final dateStr = item['createdAt']?.toString() ?? DateTime.now().toIso8601String();
              final date = DateTime.parse(dateStr).toLocal();
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFEBFFD7), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${item['orderId']?.toString().toUpperCase() ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${item['earnings'] ?? '0.00'}', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 16)),
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
