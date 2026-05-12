import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/services/db_service.dart';
import '../../../core/constants/app_colors.dart';
import '../provider/wallet_provider.dart';

class TopUpPage extends ConsumerStatefulWidget {
  const TopUpPage({super.key});

  @override
  ConsumerState<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends ConsumerState<TopUpPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  // Cache service so we can call dispose() without using ref after unmount
  late PaymentService _paymentService;
  double? _pendingAmount;

  @override
  void initState() {
    super.initState();
    _paymentService = ref.read(paymentServiceProvider);
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    final amount = _pendingAmount ?? double.tryParse(_amountController.text) ?? 0.0;
    _pendingAmount = null; // Consume the pending amount immediately

    final result = await ref.read(walletServiceProvider).topUpSuccess(
          amount: amount,
          razorpayOrderId: response.orderId!,
          razorpayPaymentId: response.paymentId!,
          razorpaySignature: response.signature!,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        // Sync both the ChangeNotifier (used in Profile/Checkout) 
        // and invalidate the Riverpod providers (used in WalletPage)
        CartProviderScope.read(context).syncWallet();
        ref.invalidate(walletHistoryProvider);
        ref.invalidate(walletTransactionsProvider);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wallet topped up successfully!'),
              backgroundColor: AppColors.accentGreen),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Verification failed'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    // Reset pending amount so no stale data can be reused
    _pendingAmount = null;
    if (!mounted) return;

    // Razorpay error code 0 means the user dismissed/cancelled the payment sheet.
    // Don't treat that as an "error" — just silently dismiss.
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    if (isCancelled) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: AppColors.error),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External Wallet: ${response.walletName}'),
          backgroundColor: AppColors.primary),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentService.dispose(); // use cached ref — safe after unmount
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Top Up Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark),
                hintText: '0',
                hintStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.primaryDark, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [500, 1000, 2000, 5000]
                  .map((amt) => ActionChip(
                        label: Text('₹$amt'),
                        onPressed: () => setState(
                            () => _amountController.text = amt.toString()),
                        backgroundColor: AppColors.scaffoldBg,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 48),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
                : ElevatedButton(
                    onPressed: () async {
                      final amountText = _amountController.text.trim();
                      final amount = double.tryParse(amountText) ?? 0.0;
                      if (amount < 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Minimum top-up is ₹100')));
                        return;
                      }

                      if (!mounted) return;
                      final profile = CartProviderScope.read(context).userProfile;
                      final messenger = ScaffoldMessenger.of(context);
                      
                      try {
                        _pendingAmount = amount;
                        await _paymentService.openCheckout(
                          amount: amount,
                          contact: profile.phone,
                          email: profile.email,
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Proceed to Payment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}

