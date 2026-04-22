import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../network/api_client.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/logger.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(apiClientProvider));
});

/// FutureProvider to fetch wallet balance for the authenticated user.
final walletBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  final wallet = await repo.getWalletBalance();
  return wallet.balance;
});

class WalletRepository {
  final ApiClient _client;

  WalletRepository(this._client);

  Future<WalletModel> getWalletBalance() async {
    try {
      final json = await _client.get(
        '${ApiClient.walletBaseUrl}/balance',
        requiresAuth: true,
      );
      return WalletModel.fromJson(json);
    } on ApiException catch (e) {
      AppLogger.e('WalletRepository.getWalletBalance: ${e.message}', e);
      throw Failure(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.e('WalletRepository.getWalletBalance: Unexpected error', e, stack);
      throw Failure(e.toString());
    }
  }
}
