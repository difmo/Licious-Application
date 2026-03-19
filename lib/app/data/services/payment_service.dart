import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class PaymentService {
  final ApiClient _apiClient;
  late Razorpay _razorpay;

  PaymentService(this._apiClient) {
    _razorpay = Razorpay();
  }

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  Future<void> openCheckout({
    required double amount,
    required String contact,
    required String email,
  }) async {
    try {
      // 1. Create order on backend
      print("Starting openCheckout... amount is $amount");
      print("Contact: '$contact', Email: '$email'");

      final orderResponse = await _apiClient.post(
        '${ApiClient.paymentBaseUrl}/create-order',
        data: {'amount': amount},
        requiresAuth: true,
      );

      print("orderResponse type: ${orderResponse.runtimeType}");
      print("orderResponse data: $orderResponse");

      final orderId = orderResponse['order']['id'];
      print("Extracted orderId: $orderId");

      // 2. Open Razorpay Checkout
      var options = {
        'key': 'rzp_test_S7lSvWtu89c6zD', // Using the test key provided
        'amount': (amount * 100).toInt(),
        'name': 'Shrimpbite',
        'order_id': orderId,
        'description': 'Wallet Top-up',
        'prefill': {'contact': contact, 'email': email},
        'external': {
          'wallets': ['paytm']
        }
      };

      print("Opening Razorpay with options: $options");
      _razorpay.open(options);
      print("Razorpay open() called successfully.");
    } catch (e, stacktrace) {
      print("=====================================");
      print("ERROR IN PAYMENT SERVICE: ${e.toString()}");
      print("STACKTRACE: $stacktrace");
      print("=====================================");
      rethrow;
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    ref.watch(apiClientProvider),
  );
});
