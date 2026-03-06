import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'order_success_page.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  int _selectedMethod = 1;
  bool _saveCard = true;

  final _nameCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _monthYearCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cardCtrl.dispose();
    _monthYearCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _CheckoutStepper(currentStep: 2),
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
                        index: 0,
                        selected: _selectedMethod == 0,
                        onTap: () => setState(() => _selectedMethod = 0),
                        label: 'Paypal',
                        child: _PaypalIcon(),
                      ),
                      const SizedBox(width: 12),
                      _PaymentMethodTile(
                        index: 1,
                        selected: _selectedMethod == 1,
                        onTap: () => setState(() => _selectedMethod = 1),
                        label: 'Credit Card',
                        child: const Icon(
                          Icons.credit_card,
                          size: 28,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PaymentMethodTile(
                        index: 2,
                        selected: _selectedMethod == 2,
                        onTap: () => setState(() => _selectedMethod = 2),
                        label: 'Apple pay',
                        child: const Icon(
                          Icons.apple,
                          size: 28,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CreditCardWidget(
                    name: _nameCtrl.text.isEmpty
                        ? 'RUSSELL AUSTIN'
                        : _nameCtrl.text.toUpperCase(),
                    cardNumber: _cardCtrl.text.isEmpty
                        ? 'XXXX XXXX XXXX 8790'
                        : _formatCardDisplay(_cardCtrl.text),
                    expiry: _monthYearCtrl.text.isEmpty
                        ? '01 / 22'
                        : _monthYearCtrl.text,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _nameCtrl,
                    hint: 'Name on the card',
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _cardCtrl,
                    hint: 'Card number',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _monthYearCtrl,
                          hint: 'Month / Year',
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _MonthYearFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _cvvCtrl,
                          hint: 'CVV',
                          icon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _saveCard,
                        onChanged: (val) => setState(() => _saveCard = val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF68B92E),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Save this card',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderSuccessPage()),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF439462),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Make a  payment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardDisplay(String raw) {
    final digits = raw.replaceAll(' ', '');
    if (digits.length < 4) return 'XXXX XXXX XXXX XXXX';
    final last4 = digits.substring(digits.length - digits.length.clamp(0, 4));
    return 'XXXX XXXX XXXX $last4';
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _CreditCardWidget extends StatelessWidget {
  final String name;
  final String cardNumber;
  final String expiry;
  const _CreditCardWidget({
    required this.name,
    required this.cardNumber,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF56C740), Color(0xFF38B24D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: _Circle(
              size: 140,
              color: Colors.white.withValues(alpha:  0.07),
            ),
          ),
          Positioned(
            right: 30,
            top: 10,
            child: _Circle(
              size: 90,
              color: Colors.white.withValues(alpha:  0.07),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -30,
            child: _Circle(
              size: 80,
              color: Colors.white.withValues(alpha:  0.07),
            ),
          ),
          Positioned(
            left: 20,
            top: 22,
            child: Row(
              children: [
                _Circle(size: 36, color: const Color(0xFFEB5502)),
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: _Circle(
                    size: 36,
                    color: const Color(0xFFEBAA02).withValues(alpha:  0.9),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 16,
            top: 18,
            child: Icon(Icons.more_vert, color: Colors.white70, size: 22),
          ),
          Positioned(
            left: 20,
            top: 70,
            child: Text(
              cardNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 70,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(
                width: 14,
                height: 14,
                color: const Color(0xFFE84393).withValues(alpha:  0.8),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARD HOLDER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:  0.7),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPIRES',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:  0.7),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        width: 10,
                        height: 10,
                        color: const Color(0xFFE8B934).withValues(alpha:  0.9),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expiry,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PaymentMethodTile extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String label;
  const _PaymentMethodTile({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.child,
    required this.label,
  });
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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaypalIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 28,
    height: 28,
    child: Center(
      child: Text(
        'P',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF003087),
        ),
      ),
    ),
  );
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
  const _StepDot({
    required this.label,
    required this.stepIndex,
    required this.currentStep,
  });
  @override
  Widget build(BuildContext context) {
    final bool done = currentStep > stepIndex;
    final bool active = currentStep == stepIndex;
    final Color bg = (done || active) ? const Color(0xFF68B92E) : Colors.white;
    final Color border = (done || active)
        ? const Color(0xFF68B92E)
        : Colors.grey.shade300;
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
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
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
            letterSpacing: 0.5,
          ),
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

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _MonthYearFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (digits.length <= 2) return newValue.copyWith(text: digits);
    final str = '${digits.substring(0, 2)} / ${digits.substring(2)}';
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}


