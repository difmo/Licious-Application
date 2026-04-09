import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/models/food_models.dart';

/// Provider for basic transaction history (returning raw data as List<dynamic>)
final walletHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(walletServiceProvider).getTransactionHistory();
});

/// Provider for detailed wallet transactions (returning List<WalletTransaction>)
final walletTransactionsProvider = FutureProvider.autoDispose<List<WalletTransaction>>((ref) async {
  final rawData = await ref.watch(walletServiceProvider).getTransactionHistory();
  return rawData.map((json) => WalletTransaction.fromJson(json)).toList();
});
