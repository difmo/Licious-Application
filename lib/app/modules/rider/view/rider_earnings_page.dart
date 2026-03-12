import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rider_service.dart';

final riderEarningsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final result = await ref.read(riderServiceProvider).getEarnings();
  // If API returns success, return data; else return mock data structure
  if (result['success'] == true) return result['data'] ?? result;
  return {
    'today': 0.0,
    'weekly': 0.0,
    'deliveries': 0,
    'walletBalance': 0.0,
  };
});

class RiderEarningsPage extends ConsumerWidget {
  const RiderEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(riderEarningsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Earnings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(riderEarningsProvider),
          ),
        ],
      ),
      body: earningsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (earnings) {
          final today = (earnings['today'] as num?)?.toDouble() ?? 0.0;
          final weekly = (earnings['weekly'] as num?)?.toDouble() ?? 0.0;
          final deliveries = (earnings['deliveries'] as num?)?.toInt() ?? 0;
          final walletBalance =
              (earnings['walletBalance'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Hero Balance Card ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF68B92E), Color(0xFF3A7A18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF68B92E).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Balance',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '₹${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _StatPill(
                              label: "Today's Pay",
                              value: '₹${today.toStringAsFixed(0)}'),
                          const SizedBox(width: 12),
                          _StatPill(
                              label: 'This Week',
                              value: '₹${weekly.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // ── Stats Grid ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _EarningsCard(
                        icon: Icons.delivery_dining_rounded,
                        iconColor: Colors.blue,
                        bgColor: const Color(0xFFE8F0FE),
                        label: 'Total Deliveries',
                        value: '$deliveries',
                      )
                          .animate(delay: 100.ms)
                          .fadeIn()
                          .slideY(begin: 0.1, end: 0),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _EarningsCard(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        bgColor: const Color(0xFFFFF8E1),
                        label: 'Avg per order',
                        value: deliveries > 0
                            ? '₹${(weekly / deliveries).toStringAsFixed(0)}'
                            : '₹0',
                      )
                          .animate(delay: 150.ms)
                          .fadeIn()
                          .slideY(begin: 0.1, end: 0),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Payout section ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text('Earnings are settled weekly to your bank',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      _PayoutRow(
                          label: 'Next Settlement', value: 'Monday, 10 Mar'),
                      const Divider(height: 24),
                      _PayoutRow(
                          label: 'Pending Balance',
                          value: '₹${weekly.toStringAsFixed(0)}'),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17)),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _EarningsCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final String label;
  final String value;
  const _PayoutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}
