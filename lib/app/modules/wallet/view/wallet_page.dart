import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/wallet_service.dart';

// Provider for wallet balance
final walletBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final result = await ref.read(walletServiceProvider).getBalance();
  return (result['balance'] as num?)?.toDouble() ?? 0.0;
});

// Provider for transaction history
final walletHistoryProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(walletServiceProvider).getTransactionHistory();
});

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final historyAsync = ref.watch(walletHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ShrimpBite',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Balance card
            balanceAsync.when(
              data: (balance) => _buildBalanceCard(balance),
              loading: () => _buildBalanceCard(null),
              error: (_, __) => _buildBalanceCard(0.0),
            ),
            const SizedBox(height: 30),
            _buildActionButtons(context),
            const SizedBox(height: 30),
            // Transaction history
            historyAsync.when(
              data: (history) => _buildTransactionHistory(history),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF114F3B),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF114F3B).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Wallet Balance',
                  style: TextStyle(
                      color: Color(0xFFA5C9AD),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                balance == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            Icons.add_circle_outline,
            'Add Money',
            Colors.blue,
            () => Navigator.pushNamed(context, AppRoutes.topUp),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildActionButton(
            context,
            Icons.history,
            'Statement',
            Colors.orange,
            () {}, // Full statement view
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<dynamic> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No transactions yet',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...transactions.map((tx) {
            final isCredit = tx['type'] == 'Credit';
            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final description = tx['description']?.toString() ?? 'Transaction';
            final date = tx['createdAt'] != null
                ? _formatDate(tx['createdAt'].toString())
                : '';
            return _TransactionItem(
              title: description,
              date: date,
              amount: '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
              isCredit: isCredit,
            );
          }),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isCredit;

  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.restaurant_rounded,
              color: isCredit ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isCredit ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
