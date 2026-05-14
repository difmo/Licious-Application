import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/db_service.dart';
import '../provider/wallet_provider.dart';
import '../../../core/utils/auth_guard.dart';
import '../../auth/provider/auth_provider.dart' as auth;

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = CartProviderScope.of(context);
    final balance = cart.walletBalance;
    final historyAsync = ref.watch(walletHistoryProvider);
    final isAuthenticated = ref.watch(auth.isAuthenticatedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Wallet',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: isAuthenticated ? [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              CartProviderScope.read(context).syncWallet();
              ref.invalidate(walletHistoryProvider);
            },
          ),
        ] : null,
      ),
      body: !isAuthenticated 
        ? _buildGuestView(context, ref)
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Balance card
                _buildBalanceCard(balance),
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

  Widget _buildGuestView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF68B92E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Color(0xFF68B92E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Wallet is Waiting',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login to see your balance, add money, and view transaction history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => AuthGuard.run(context, ref, () {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF68B92E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Login / Signup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double? balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF68B92E), Color(0xFF4A8B1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF68B92E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
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
            () => Navigator.pushNamed(context, AppRoutes.walletStatement),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
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
