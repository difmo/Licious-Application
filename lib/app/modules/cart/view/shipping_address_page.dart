import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/api_client.dart';
import '../provider/address_provider.dart';
import 'payment_method_page.dart';

class ShippingAddressPage extends ConsumerStatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  ConsumerState<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends ConsumerState<ShippingAddressPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  
  String _selectedLabel = 'Home';
  final List<Map<String, dynamic>> _labels = [
    {'name': 'Home', 'icon': Icons.home_rounded},
    {'name': 'Office', 'icon': Icons.work_rounded},
    {'name': 'Other', 'icon': Icons.location_on_rounded},
  ];
  
  bool _isDefault = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAddressAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(addressServiceProvider);
      await service.saveAddress(
        label: _selectedLabel,
        fullAddress: _fullAddressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        isDefault: _isDefault,
      );

      if (!mounted) return;
      
      // Successfully saved! Proceed to Payment
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e is ApiException ? e.message : e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shipping Address',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: _CheckoutStepper(currentStep: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address Label',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _labels.map((lbl) {
                        bool isSelected = _selectedLabel == lbl['name'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedLabel = lbl['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF439462) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF439462) : Colors.grey.shade200,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF439462).withValues(alpha:  0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    lbl['icon'],
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lbl['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _fullAddressCtrl,
                      label: 'Full Address',
                      hint: 'Flat no, House no, Street name',
                      icon: Icons.map_rounded,
                      validator: (v) => v!.isEmpty ? 'Please enter your address' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _cityCtrl,
                            label: 'City',
                            hint: 'e.g. Lucknow',
                            icon: Icons.location_city_rounded,
                            validator: (v) => v!.isEmpty ? 'Field required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _pincodeCtrl,
                            label: 'Pincode',
                            hint: '123456',
                            icon: Icons.pin_drop_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.length < 6 ? 'Invalid pin' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _stateCtrl,
                      label: 'State',
                      hint: 'e.g. Uttar Pradesh',
                      icon: Icons.holiday_village_rounded,
                      validator: (v) => v!.isEmpty ? 'Please enter state' : null,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF439462).withValues(alpha:  0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF439462),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as default address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  'Use this for all future orders',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isDefault,
                            activeTrackColor: const Color(0xFF439462),
                            activeThumbColor: Colors.white,
                            onChanged: (val) => setState(() => _isDefault = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: const Color(0xFF439462),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF439462), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAddressAndProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF439462),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save & Continue',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          _StepDot(label: 'CART', stepIndex: 0, currentStep: currentStep),
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
    final Color primary = const Color(0xFF38B24D);
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (done || active) ? primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: (done || active) ? primary : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: active ? [
              BoxShadow(
                color: primary.withValues(alpha:  0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: (done || active) ? FontWeight.bold : FontWeight.w500,
            color: (done || active) ? primary : Colors.grey.shade400,
            letterSpacing: 0.8,
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22, left: 8, right: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF38B24D) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}


