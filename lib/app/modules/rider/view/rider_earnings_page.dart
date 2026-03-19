import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/rider_service.dart';

// ── Provider ────────────────────────────────────────────────────────────────

final riderEarningsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final riderService = ref.read(riderServiceProvider);
  final result = await riderService.getEarnings();

  Map<String, dynamic> data = {};

  // ── Shape 1: { success: true, data: { today, weekly, ... } }
  if (result['success'] == true && result['data'] is Map) {
    data = Map<String, dynamic>.from(result['data'] as Map);
  }
  // ── Shape 2: { success: true, today: ..., weekly: ... }  (flat)
  else if (result['success'] == true) {
    data = Map<String, dynamic>.from(result);
    data.remove('success');
    data.remove('message');
  }
  // ── Shape 3: raw data object – no success flag but has numeric fields
  else {
    final hasData = result.keys.any((k) => [
          'today',
          'weekly',
          'deliveries',
          'walletBalance',
          'balance',
          'todayEarnings',
          'weeklyEarnings',
          'totalDeliveries'
        ].contains(k));
    if (hasData) {
      data = Map<String, dynamic>.from(result);
    }
  }

  // ── Fallback: Calculate from History if empty ─────────────────────────────
  final hasDeliveries =
      data['deliveries'] != null || data['totalDeliveries'] != null;
  final hasEarnings = data['weekly'] != null || data['walletBalance'] != null;

  if (!hasDeliveries ||
      !hasEarnings ||
      (data['deliveries'] == 0 && data['weekly'] == 0)) {
    try {
      final history = await riderService.getDeliveryHistory();
      if (history.isNotEmpty) {
        data['deliveries'] = history.length;
        double total = 0;
        for (final item in history) {
          total += (item['commission'] ?? item['earnings'] ?? 30.0);
        }
        data['weekly'] = total;
        data['walletBalance'] = total;
        data['today'] =
            0.0; // Hard to guess today from history without checking dates
      }
    } catch (_) {}
  }

  // Ensure minimum defaults
  return {
    'today': data['today'] ?? 0.0,
    'weekly': data['weekly'] ?? 0.0,
    'deliveries': data['deliveries'] ?? 0,
    'walletBalance': data['walletBalance'] ?? 0.0,
    'avgPerOrder': data['avgPerOrder'] ?? 0.0,
    'pendingBalance': data['pendingBalance'] ?? 0.0,
    ...data,
  };
});

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Returns the next Monday from today as a formatted string, e.g. "Monday, 17 Mar"
String _nextSettlementDate() {
  final now = DateTime.now();
  final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
  final nextMonday =
      now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  return DateFormat('EEEE, d MMM').format(nextMonday);
}

double _parseNum(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v == null) continue;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
  }
  return 0;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class RiderEarningsPage extends ConsumerWidget {
  const RiderEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(riderEarningsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: const [],
      ),
      body: earningsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load earnings',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(riderEarningsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen),
              ),
            ],
          ),
        ),
        data: (earnings) {
          // ── Parse earnings fields (multi-key fallback for different API schemas)
          final walletBalance = _parseNum(earnings, [
            'walletBalance',
            'wallet_balance',
            'balance',
            'totalEarnings',
            'total_earnings',
            'totalEarning',
            'total_earning',
            'totalEarninag'
          ]);
          final today = _parseNum(earnings,
              ['today', 'todayEarnings', 'today_earnings', 'todayPay']);
          final weekly = _parseNum(earnings, [
            'weekly',
            'weeklyEarnings',
            'weekly_earnings',
            'thisWeek',
            'this_week',
            'totalEarnings',
            'total_earnings',
            'totalEarning',
            'total_earning',
            'totalEarninag'
          ]);
          final deliveries = _parseInt(earnings, [
            'deliveries',
            'totalDeliveries',
            'total_deliveries',
            'deliveryCount',
            'totalOrders',
            'total_orders',
            'totalOrder',
            'total_order',
            'orders'
          ]);
          final avgPerOrder = deliveries > 0
              ? weekly / deliveries
              : _parseNum(earnings, [
                  'avgPerOrder',
                  'avg_per_order',
                  'averagePerOrder',
                  'avgOrder'
                ]);
          final pendingBalance = _parseNum(
              earnings, ['pendingBalance', 'pending_balance', 'pending']);
          final nextSettlement = earnings['nextSettlement'] as String? ??
              earnings['next_settlement'] as String? ??
              _nextSettlementDate();

          return RefreshIndicator(
            color: AppColors.accentGreen,
            onRefresh: () async => ref.invalidate(riderEarningsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Hero Balance Card ──────────────────────────────────────
                  _WalletBalanceCard(
                    walletBalance: walletBalance,
                    today: today,
                    weekly: weekly,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // ── Stats Grid ────────────────────────────────────────────
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
                          value: '₹${avgPerOrder.toStringAsFixed(0)}',
                        )
                            .animate(delay: 150.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Payout Section ────────────────────────────────────────
                  _PayoutCard(
                    nextSettlement: nextSettlement,
                    pendingBalance: pendingBalance > 0
                        ? pendingBalance
                        : weekly, // fallback to weekly if no pending field
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Wallet Balance Card ───────────────────────────────────────────────────────

class _WalletBalanceCard extends StatelessWidget {
  final double walletBalance;
  final double today;
  final double weekly;
  const _WalletBalanceCard({
    required this.walletBalance,
    required this.today,
    required this.weekly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'Wallet Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${walletBalance.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatPill(
                label: "Today's Pay",
                value: '₹${today.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 12),
              _StatPill(
                label: 'This Week',
                value: '₹${weekly.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payout Card ───────────────────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  final String nextSettlement;
  final double pendingBalance;
  const _PayoutCard({
    required this.nextSettlement,
    required this.pendingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'Payout',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Earnings are settled weekly to your bank',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          _PayoutRow(
            label: 'Next Settlement',
            value: nextSettlement,
          ),
          const Divider(height: 24),
          _PayoutRow(
            label: 'Pending Balance',
            value: '₹${pendingBalance.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

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
