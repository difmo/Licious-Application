import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class WalletService {
  final ApiClient _apiClient;

  WalletService(this._apiClient);

  Future<Map<String, dynamic>> getBalance() async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.walletBaseUrl}/balance',
        requiresAuth: true,
      );
      
      double extractedBalance = 0.0;
      if (response['balance'] != null) {
        extractedBalance = (response['balance'] as num).toDouble();
      } else if (response['data'] != null && response['data']['balance'] != null) {
        extractedBalance = (response['data']['balance'] as num).toDouble();
      } else if (response['walletBalance'] != null) {
        extractedBalance = (response['walletBalance'] as num).toDouble();
      }

      return {
        'success': response['success'] ?? true,
        'balance': extractedBalance,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'balance': 0.0};
    }
  }

  Future<List<dynamic>> getTransactionHistory() async {
    try {
      final response = await _apiClient.get(
        '${ApiClient.walletBaseUrl}/history',
        requiresAuth: true,
      );
      return response['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> topUpSuccess({
    required double amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiClient.walletBaseUrl}/topup-success',
        data: {
          'amount': amount,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(ref.watch(apiClientProvider));
});
