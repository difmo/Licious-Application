import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../data/services/rider_service.dart';

final riderOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final riderService = ref.watch(riderServiceProvider);
  return riderService.getAssignedOrders();
});

class RiderHomePage extends ConsumerWidget {
  const RiderHomePage({super.key});

  Future<void> _handleResponse(BuildContext context, WidgetRef ref, String orderId, String response) async {
    final riderService = ref.read(riderServiceProvider);
    final result = await riderService.respondToOrder(orderId: orderId, response: response);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      if (result['success']) {
        ref.invalidate(riderOrdersProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final ordersAsync = ref.watch(riderOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        backgroundColor: const Color(0xFF0EA5E9),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(riderOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(riderOrdersProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, size: 40, color: Color(0xFF0EA5E9)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Rider Name',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user?.phoneNumber ?? 'Phone Number',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Assigned Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.delivery_dining, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'No active deliveries assigned',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isPending = order['riderAssignmentStatus'] == 'Pending';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order #${order['orderId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(order['status'], style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const Divider(),
                              Text('Customer: ${order['user']?['name'] ?? 'N/A'}'),
                              Text('Address: ${order['deliveryAddress']?['address'] ?? 'N/A'}'),
                              const SizedBox(height: 12),
                              if (isPending)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleResponse(context, ref, order['orderId'], 'Accepted'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleResponse(context, ref, order['orderId'], 'Rejected'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                  ],
                                )
                              else if (order['riderAssignmentStatus'] == 'Accepted')
                                const Text('Status: Accepted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
