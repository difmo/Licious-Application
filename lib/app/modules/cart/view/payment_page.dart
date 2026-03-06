import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import 'order_success_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'Credit Card';
  bool _saveCard = true;

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: 32),

            // Payment Methods
            Row(
              children: [
                _buildMethodSelector(
                  'UPI',
                  Icons.mobile_screen_share_rounded,
                  Colors.indigo,
                ),
                const SizedBox(width: 12),
                _buildMethodSelector(
                  'Credit Card',
                  Icons.credit_card,
                  Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildMethodSelector('Apple pay', Icons.apple, Colors.black),
              ],
            ),
            const SizedBox(height: 24),

            if (_selectedMethod == 'Credit Card') ...[
              // Card Preview
              _buildCardPreview(),
              const SizedBox(height: 24),

              // Form Fields
              _buildIconTextField(Icons.person_outline, 'Name on the card'),
              const SizedBox(height: 12),
              _buildIconTextField(Icons.credit_card_outlined, 'Card number'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildIconTextField(
                      Icons.calendar_today_outlined,
                      'Month / Year',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIconTextField(Icons.lock_outline, 'CVV'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle
              Row(
                children: [
                  Switch(
                    value: _saveCard,
                    onChanged: (v) => setState(() => _saveCard = v),
                    activeThumbColor: const Color(0xFF68B92E),
                    activeTrackColor: const Color(0xFFEBFFD7),
                  ),
                  const Text(
                    'Save this card',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildAlternateMethodInfo(),
            ],

            const SizedBox(height: 32),

            // Order Summary
            _buildOrderSummary(cart),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Finalize Order Logic
                  cart.clearCart();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderSuccessPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF439462),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Pay ₹${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternateMethodInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBFFD7), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF68B92E), size: 40),
          const SizedBox(height: 16),
          Text(
            'Secure Payment via $_selectedMethod',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You will be redirected to complete your payment securely.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Shipping',
            '₹${cart.shippingCharges.toStringAsFixed(0)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F4F8)),
          ),
          _buildSummaryRow(
            'Total Amount',
            '₹${cart.total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? const Color(0xFF1A1A1A) : Colors.grey,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? const Color(0xFF68B92E) : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, 'DELIVERY', true),
        _buildStepLine(true),
        _buildStep(2, 'ADDRESS', true),
        _buildStepLine(true),
        _buildStep(3, 'PAYMENT', true, isActive: true),
      ],
    );
  }

  Widget _buildStep(
    int num,
    String label,
    bool isCompleted, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF68B92E)
                : Colors.grey.withValues(alpha:  0.2),
            shape: BoxShape.circle,
          ),
          child: isCompleted && !isActive
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Center(
                  child: Text(
                    '$num',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? const Color(0xFFA1A1A1) : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: isCompleted
          ? const Color(0xFF68B92E)
          : Colors.grey.withValues(alpha:  0.2),
    );
  }

  Widget _buildMethodSelector(String label, IconData icon, Color color) {
    bool isSelected = _selectedMethod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF68B92E).withValues(alpha:  0.5)
                  : Colors.grey.shade100,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF68B92E)
                    : color.withValues(alpha:  0.6),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF68B92E), Color(0xFF439462)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:  0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-15, 0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha:  0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
          const Spacer(),
          const Text(
            'XXXX XXXX XXXX 8790',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:  0.6),
                      fontSize: 10,
                    ),
                  ),
                  const Text(
                    'RUSSELL AUSTIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:  0.6),
                      fontSize: 10,
                    ),
                  ),
                  const Text(
                    '01 / 22',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconTextField(IconData icon, String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
      ),
    );
  }
}


