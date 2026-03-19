import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/wallet_service.dart';
import 'package:intl/intl.dart';

// Provider for filtered wallet transactions
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>((ref) async {
  final rawData = await ref.read(walletServiceProvider).getTransactionHistory();
  return rawData.map((json) => WalletTransaction.fromJson(json)).toList();
});

class WalletStatementScreen extends ConsumerStatefulWidget {
  const WalletStatementScreen({super.key});

  @override
  ConsumerState<WalletStatementScreen> createState() =>
      _WalletStatementScreenState();
}

class _WalletStatementScreenState extends ConsumerState<WalletStatementScreen> {
  String _searchQuery = '';
  String _selectedDateFilter = '7 Days';

  final List<String> _dateFilters = ['Today', '7 Days', '30 Days'];
  final List<String> _typeFilters = ['All'];

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Wallet Statement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showDownloadOptions(context),
            tooltip: 'Download Statement',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filteredTx = _applyFilters(transactions);
                if (filteredTx.isEmpty) return _buildEmptyState();

                return _buildTransactionList(filteredTx);
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF68B92E))),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search by Order ID or Trans ID',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Date Filters
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dateFilters.length,
              itemBuilder: (context, index) {
                final filter = _dateFilters[index];
                final isSelected = _selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    onSelected: (val) =>
                        setState(() => _selectedDateFilter = filter),
                    selectedColor: const Color(0xFF68B92E),
                    backgroundColor: const Color(0xFFF1F4F8),
                    elevation: 0,
                    pressElevation: 0,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Type Filter (Only "All" allowed)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _typeFilters.length,
              itemBuilder: (context, index) {
                final filter = _typeFilters[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white)),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF439462),
                    backgroundColor: const Color(0xFFF1F4F8),
                    elevation: 0,
                    pressElevation: 0,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    // Group transactions by date
    Map<String, List<WalletTransaction>> grouped = {};
    for (var tx in transactions) {
      String date = DateFormat('MMMM dd, yyyy').format(tx.createdAt);
      if (grouped[date] == null) grouped[date] = [];
      grouped[date]!.add(tx);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildOpeningBalanceCard(transactions),
        const SizedBox(height: 20),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13),
                ),
              ),
              ...entry.value
                  .map((tx) => _TransactionItemWidget(transaction: tx)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildOpeningBalanceCard(List<WalletTransaction> transactions) {
    // Just a placeholder card showing summary
    final totalCredit = transactions
        .where((t) => t.type == 'Credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalDebit = transactions
        .where((t) => t.type == 'Debit')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Statement Summary',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'Total money added', '+₹${totalCredit.toStringAsFixed(0)}',
                  Colors.green),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Expense', '-₹${totalDebit.toStringAsFixed(0)}',
                  Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No transactions found',
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  List<WalletTransaction> _applyFilters(List<WalletTransaction> all) {
    return all.where((tx) {
      // Search filter
      bool matchesSearch =
          tx.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.orderId.toLowerCase().contains(_searchQuery.toLowerCase());

      // Date filter
      DateTime now = DateTime.now();
      bool matchesDate = true;
      if (_selectedDateFilter == 'Today') {
        matchesDate = tx.createdAt.day == now.day &&
            tx.createdAt.month == now.month &&
            tx.createdAt.year == now.year;
      } else if (_selectedDateFilter == '7 Days') {
        matchesDate =
            tx.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_selectedDateFilter == '30 Days') {
        matchesDate =
            tx.createdAt.isAfter(now.subtract(const Duration(days: 30)));
      }

      return matchesSearch && matchesDate;
    }).toList();
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Download Statement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent),
              title: const Text('Download as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading PDF...')));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.table_chart_rounded, color: Colors.green),
              title: const Text('Download as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading Excel...')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItemWidget extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionItemWidget({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.type == 'Credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F4F8)),
      ),
      child: Row(
        children: [
          _buildIcon(isCredit),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.category == 'Top-up'
                          ? 'Wallet Top-up'
                          : 'Order Payment',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    _buildStatusBadge(transaction.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('ID: ${transaction.id}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(transaction.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isCredit ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ₹${transaction.balanceAfter.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isCredit) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isCredit ? Colors.green : Colors.grey).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCredit ? Icons.add_rounded : Icons.shopping_bag_rounded,
        color: isCredit ? Colors.green : Colors.grey[700],
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'success':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
