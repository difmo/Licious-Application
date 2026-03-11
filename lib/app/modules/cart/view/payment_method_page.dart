import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:licius_application/app/data/services/db_service.dart';
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
  final List<String> _days = [];
  final List<String> _frequencies = [
    'Daily',
    'Alternate Days',
    'Weekly',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = CartProviderScope.of(context);
      cartProvider.syncWallet();
      cartProvider.loadCartFromApi();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
                  Row(
                    children: [
                      _PaymentMethodTile(
                        index: 3,
                        selected: true,
                        onTap: () {},
                        label: 'Wallet',
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            size: 28, color: Color(0xFF439462)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF439462).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF439462).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: Color(0xFF439462), size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wallet Balance',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            Text(
                              '₹${cartProvider.walletBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF439462)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (cartProvider.walletBalance < cartProvider.total)
                          const Text('Insufficient',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
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
                    children: [
                      _TypeButton(
                        label: 'One-time Order',
                        selected: _orderType == 0,
                        onTap: () => setState(() => _orderType = 0),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(width: 12),
                      _TypeButton(
                        label: 'Daily Deliveries',
                        selected: _orderType == 1,
                        onTap: () => setState(() => _orderType = 1),
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
                          onSelected: (val) => setState(() => _frequency = f),
                          selectedColor: const Color(0xFF439462),
                          labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.black,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal),
                        );
                      }).toList(),
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
                        try {
                          final selectedAddr = cartProvider.selectedAddress;
                          if (selectedAddr == null) {
                            throw Exception('Please select a delivery address');
                          }

                          if (cartProvider.walletBalance < cartProvider.total) {
                            throw Exception(
                                'Insufficient wallet balance. Please top up.');
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
                                customDays: _frequency == 'Custom' ? _days : [],
                              );
                              if (res['success'] != true) {
                                throw Exception(res['message'] ??
                                    'Failed to subscribe ${item.title}');
                              }
                            }
                            // Success path for all items
                            await cartProvider.syncWallet();
                            cartProvider.clearCart();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const OrderSuccessPage()),
                                (route) => route.isFirst);
                          } else {
                            // ONE-TIME ORDER
                            final orderService = ref.read(orderServiceProvider);
                            final response = await orderService.placeOrder(
                                deliveryAddress: deliveryAddressMap,
                                paymentMethod: 'Wallet');
                            if (response['success'] == true) {
                              await cartProvider.syncWallet();
                              cartProvider.clearCart();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const OrderSuccessPage()),
                                  (route) => route.isFirst);
                            } else {
                              throw Exception(response['message'] ??
                                  'Failed to place order');
                            }
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF439462) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    selected ? const Color(0xFF439462) : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : Colors.grey, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String label;
  const _PaymentMethodTile(
      {required this.index,
      required this.selected,
      required this.onTap,
      required this.child,
      required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: const Color(0xFF38B24D), width: 2)
                : null,
          ),
          child: Column(
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? const Color(0xFF38B24D)
                        : Colors.grey.shade600,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
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
