import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:licius_application/app/data/services/db_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/subscription_service.dart';
import 'order_success_page.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  bool _isLoading = false;
  int _orderType = 0; // 0: One-time, 1: Scheduled
  String _frequency = 'Daily';
  List<String> _selectedDays = [];
  late DateTime _startDate;
   String _selectedPaymentMethod = 'Razorpay'; // Default to Direct Pay for One-time
   String? _currentOrderId; 
  late PaymentService _paymentService;
  final List<String> _frequencies = [
    'Daily',
    'Alternate Days',
    'Weekly',
  ];
  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    // Default start date = tomorrow
    _startDate = DateTime.now().add(const Duration(days: 1));

    // Sync wallet balance when page is opened to reflect latest money
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CartProviderScope.of(context).syncWallet();
      }
    });

    _paymentService = ref.read(paymentServiceProvider);
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // This is called when Direct Pay (Razorpay) succeeds
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cartProvider = CartProviderScope.of(context);

    try {
      // 1. Tell backend to verify the order payment
      final orderService = ref.read(orderServiceProvider);
      final verifyRes = await orderService.verifyOrderPayment(
        orderId: _currentOrderId ?? '', 
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (verifyRes['success'] != true) {
        throw Exception(verifyRes['message'] ?? 'Payment verification failed');
      }
      
      // 2. Clear cart and sync wallet status
      await cartProvider.syncWallet();
      cartProvider.clearCart();
      ref.invalidate(activeOrdersProvider);
      
      // 3. Redirect to success page
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => OrderSuccessPage(
                order: verifyRes['order'] ?? verifyRes['data'],
              )),
          (route) => route.isFirst);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Payment Verification Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) async {
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      if (_currentOrderId != null) {
        // Notify backend that order should be cancelled as user backed out
        final orderService = ref.read(orderServiceProvider);
        await orderService.cancelOrder(_currentOrderId!);
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}')),
      );
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF439462),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = CartProviderScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const _CheckoutStepper(currentStep: 2),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Payment Method Section
                   _buildPaymentMethodCard(cartProvider),
                  const SizedBox(height: 24),
                   if (_orderType == 1 && _selectedPaymentMethod == 'Wallet')
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Note: Subscriptions are prepaid from your wallet daily.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text('Order Summary',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        ...cartProvider.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.title} x ${item.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.totalPrice).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Shipping',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                                '₹${cartProvider.shippingCharges.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '₹${cartProvider.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF439462)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Order Type',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _TypeButton(
                        label: 'One-time Order',
                        selected: _orderType == 0,
                        onTap: () {
                          setState(() {
                            _orderType = 0;
                            _selectedPaymentMethod = 'Razorpay';
                          });
                        },
                        icon: Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(width: 10),
                      _TypeButton(
                        label: 'Daily Deliveries',
                        selected: _orderType == 1,
                        onTap: () {
                          setState(() {
                            _orderType = 1;
                            _selectedPaymentMethod = 'Wallet';
                          });
                        },
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_orderType == 1) ...[
                    const Text('Delivery Frequency',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _frequencies.map((f) {
                        bool isSel = _frequency == f;
                        return ChoiceChip(
                          label: Text(f),
                          selected: isSel,
                          onSelected: (_) => setState(() {
                            _frequency = f;
                            if (f != 'Weekly') _selectedDays = [];
                          }),
                          selectedColor: const Color(0xFF439462),
                          labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.black,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal),
                        );
                      }).toList(),
                    ),
                    if (_frequency == 'Weekly') ...[
                      const SizedBox(height: 16),
                      const Text('Select Delivery Days',
                          style: TextStyle(
                               fontSize: 14,
                               fontWeight: FontWeight.bold,
                               color: Color(0xFF1F2937))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _weekDays.map((day) {
                          final short = day.substring(0, 3);
                          final selected = _selectedDays.contains(day);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedDays.remove(day);
                              } else {
                                _selectedDays.add(day);
                              }
                            }),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF439462)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF439462)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(short,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87)),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedDays.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Please select at least one day',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                    const SizedBox(height: 16),
                    // Start Date Picker
                    const Text('Start Date',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF439462)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF439462), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${_startDate.day.toString().padLeft(2, '0')} / ${_startDate.month.toString().padLeft(2, '0')} / ${_startDate.year}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF439462)),
                            ),
                            const Spacer(),
                            const Text('Tap to change',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          final selectedAddr = cartProvider.selectedAddress;
                          if (selectedAddr == null) {
                            throw Exception('Please select a delivery address');
                          }

                          // Wallet balance check for Scheduled or Wallet-based one-time orders
                          final isWalletPay = _selectedPaymentMethod == 'Wallet' || _orderType == 1;
                          if (isWalletPay && cartProvider.walletBalance < cartProvider.total) {
                            _showInsufficientFundsDialog(cartProvider);
                            return;
                          }

                          final deliveryAddressMap = {
                            'address': selectedAddr.street,
                            'city':
                                selectedAddr.details.split(',').first.trim(),
                            'state': selectedAddr.details.contains(',')
                                ? selectedAddr.details
                                    .split(',')[1]
                                    .trim()
                                    .split(' ')
                                    .first
                                : 'Unknown',
                            'pincode': selectedAddr.details.split(' ').last,
                          };

                          if (_orderType == 1) {
                            // SCHEDULED ORDER
                            final subService =
                                ref.read(subscriptionServiceProvider);
                            for (final item in cartProvider.items) {
                              final res = await subService.subscribeToProduct(
                                productId: item.id,
                                frequency: _frequency,
                                quantity: item.quantity,
                                variantId: item.variantId,
                                weightLabel: item.weightLabel ?? item.subtitle,
                                customDays:
                                    _frequency == 'Weekly' ? _selectedDays : [],
                                startDate: _startDate,
                              );
                              if (res['success'] != true) {
                                throw Exception(res['message'] ??
                                    'Failed to subscribe ${item.title}');
                              }
                            }
                            // Success path for all items
                            await Future.delayed(const Duration(milliseconds: 1500));
                            await cartProvider.syncWallet();
                            cartProvider.clearCart();
                            navigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const OrderSuccessPage()),
                                (route) => route.isFirst);
                          } else {
                            // ONE-TIME ORDER
                            final orderService = ref.read(orderServiceProvider);
                            
                            // 1. Force sync local cart to server (FIX for "Cart is empty" server error)
                            // Even if it takes a moment, it's better than a failed order.
                            await cartProvider.syncLocalCartToServer();

                            // 2. Map items for redundancy
                            final itemsList = cartProvider.items.map((item) => {
                              'productId': item.id,
                              'quantity': item.quantity,
                              'variantId': item.variantId,
                              'weightLabel': item.weightLabel,
                            }).toList();

                            // 3. Place Order
                            final response = await orderService.placeOrder(
                                deliveryAddress: deliveryAddressMap,
                                paymentMethod: _selectedPaymentMethod,
                                items: itemsList);

                            if (response['success'] == true) {
                              if (_selectedPaymentMethod == 'Razorpay') {
                                // DIRECT PAY FLOW
                                final razorpayOrderId = response['razorpayOrderId'] ?? response['orderId'];
                                _currentOrderId = response['orderId']?.toString() ?? response['order']?['_id']?.toString();
                                
                                if (razorpayOrderId == null) {
                                  throw Exception('Failed to initialize Direct Payment. No order ID returned.');
                                }
                                
                                final profile = cartProvider.userProfile;
                                await _paymentService.openCheckout(
                                  amount: cartProvider.total,
                                  contact: profile.phone,
                                  email: profile.email,
                                  razorpayOrderId: razorpayOrderId,
                                  description: 'One-time Order Payment',
                                );
                                // The rest is handled by _handlePaymentSuccess
                              } else {
                                // WALLET SUCCESS FLOW
                                await Future.delayed(const Duration(milliseconds: 1500));
                                await cartProvider.syncWallet();
                                cartProvider.clearCart();
                                ref.invalidate(activeOrdersProvider);
                                navigator.pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => OrderSuccessPage(
                                            order: response['order'])),
                                    (route) => route.isFirst);
                              }
                            } else {
                              throw Exception(response['message'] ??
                                  'Failed to place order');
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF439462),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Make a payment',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog(dynamic cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Insufficient Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your wallet balance is not enough to complete this order.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Required Amount:', style: TextStyle(color: Colors.grey)),
                  Text(
                    '₹${cartProvider.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(context, '/wallet').then((_) {
                if (mounted) {
                  cartProvider.syncWallet();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF439462),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Top Up Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(dynamic cartProvider) {
    if (_orderType == 0) {
      // One-time Order -> Direct Pay only
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.payment_rounded, color: Colors.grey, size: 24),
            SizedBox(width: 12),
            Text(
              'Direct Pay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      );
    } else {
      // Subscription -> Wallet only
      final bool isInsufficient = cartProvider.walletBalance < cartProvider.total;
      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/wallet').then((_) {
            if (mounted) {
              cartProvider.syncWallet();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Color(0xFF439462), size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Wallet ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '(₹${cartProvider.walletBalance.toStringAsFixed(0)} ${isInsufficient ? "· Insufficient" : ""})',
                        style: TextStyle(
                          fontSize: 15,
                          color: isInsufficient ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  const _TypeButton(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF439462) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? const Color(0xFF439462) : Colors.grey.shade200,
                width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutStepper extends StatelessWidget {
  final int currentStep;
  const _CheckoutStepper({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _StepDot(label: 'DELIVERY', stepIndex: 0, currentStep: currentStep),
          _StepLine(active: currentStep >= 1),
          _StepDot(label: 'ADDRESS', stepIndex: 1, currentStep: currentStep),
          _StepLine(active: currentStep >= 2),
          _StepDot(label: 'PAYMENT', stepIndex: 2, currentStep: currentStep),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final int stepIndex;
  final int currentStep;
  const _StepDot(
      {required this.label,
      required this.stepIndex,
      required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final bool done = currentStep > stepIndex;
    final bool active = currentStep == stepIndex;
    final Color bg = (done || active) ? const Color(0xFF68B92E) : Colors.white;
    final Color border =
        (done || active) ? const Color(0xFF68B92E) : Colors.grey.shade300;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text('${stepIndex + 1}',
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: (done || active)
                  ? const Color(0xFF38B24D)
                  : Colors.grey.shade400,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 20),
          color: active ? const Color(0xFF38B24D) : Colors.grey.shade300,
        ),
      );
}
