import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage>
    with TickerProviderStateMixin {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  final FocusNode _cvvFocus = FocusNode();

  String _cardNumber = "5129 1330 6701 0096";
  String _cardName = "AMIT KUMAR";
  String _cardExpiry = "06/2026";
  String _cardCvv = "***";

  bool _isBack = false;

  // Animations
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));

    _numberController.addListener(_formatCardNumber);
    _nameController.addListener(() {
      setState(() => _cardName = _nameController.text.isEmpty
          ? "AMIT KUMAR"
          : _nameController.text.toUpperCase());
    });
    _expiryController.addListener(_formatExpiry);
    _cvvController.addListener(() {
      setState(() =>
          _cardCvv = _cvvController.text.isEmpty ? "***" : _cvvController.text);
    });

    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_isBack) {
        _flipCard();
      } else if (!_cvvFocus.hasFocus && _isBack) {
        _flipCard();
      }
    });

    // Initial values from screenshot
    _numberController.text = "5129 1330 6701 0096";
    _nameController.text = "AMIT KUMAR";
    _expiryController.text = "06/2026";
    _cvvController.text = "";
  }

  @override
  void dispose() {
    _flipController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isBack = !_isBack;
    HapticFeedback.lightImpact();
  }

  void _formatCardNumber() {
    String raw = _numberController.text.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += raw[i];
    }

    if (formatted != _numberController.text) {
      _numberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    setState(() {
      _cardNumber = formatted.isEmpty ? "5129 1330 6701 0096" : formatted;
    });
  }

  void _formatExpiry() {
    setState(() {
      _cardExpiry =
          _expiryController.text.isEmpty ? "06/2026" : _expiryController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Card',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Virtual Card Preview
              AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final isBack = _flipAnimation.value > 0.5;
                  final angle = _flipAnimation.value * math.pi;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: FractionalOffset.center,
                    child: isBack
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: FractionalOffset.center,
                            child: _buildCardBack(),
                          )
                        : _buildCardFront(),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Card Number Input
              _buildInputField(
                label: "Card Number",
                controller: _numberController,
                keyboardType: TextInputType.number,
                trailing: const Text(
                  'VISA',
                  style: TextStyle(
                    color: Color(0xFF1A3E9F),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cardholder Name Input
              _buildInputField(
                label: "Cardholder Name",
                controller: _nameController,
                keyboardType: TextInputType.name,
                trailing: const Icon(Icons.camera_alt_outlined,
                    color: Colors.grey, size: 20),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: "Expiry & Date",
                      controller: _expiryController,
                      placeholder: "06/2026",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: "CVV",
                      controller: _cvvController,
                      placeholder: "***",
                      obscureText: true,
                      focusNode: _cvvFocus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Add Card Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text('Add Card',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B7CEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: const Color(0xFF3B7CEB).withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4DA7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B7CEB),
            const Color(0xFF203A84),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203A84).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.wifi, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          // Chip
          Container(
            width: 45,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(4),
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                  9,
                  (index) => Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      )),
            ),
          ),
          const Spacer(),
          Text(
            _cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "EXP: $_cardExpiry",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFFDEDDE3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            height: 45,
            color: Colors.black,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    color: Colors.white,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _cardCvv,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? trailing,
    FocusNode? focusNode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }
}
