import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/api_client.dart';
import '../../../data/services/db_service.dart';
import 'payment_method_page.dart';

class ShippingAddressPage extends ConsumerStatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  ConsumerState<ShippingAddressPage> createState() =>
      _ShippingAddressPageState();
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
  bool _showAddForm = false;

  @override
  void dispose() {
    _fullAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final cart = CartProviderScope.of(context);
      final service =
          cart.addressService!; // Guaranteed if CartProvider is initialized

      final result = await service.saveAddress(
        label: _selectedLabel,
        fullAddress: _fullAddressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        isDefault: _isDefault,
      );

      if (result['success']) {
        await cart.loadAddresses();
        if (mounted) {
          setState(() {
            _showAddForm = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address saved successfully!')));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error: ${e is ApiException ? e.message : e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final addresses = cart.addresses;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
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
            child: const _CheckoutStepper(currentStep: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (addresses.isNotEmpty && !_showAddForm) ...[
                    const Text(
                      'Select Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final addr = addresses[index];
                        final isSelected = cart.selectedAddressIndex == index;
                        return GestureDetector(
                          onTap: () => cart.selectAddress(index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF439462)
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF439462)
                                            .withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  addr.title == 'Home'
                                      ? Icons.home_rounded
                                      : addr.title == 'Office'
                                          ? Icons.work_rounded
                                          : Icons.location_on_rounded,
                                  color: isSelected
                                      ? const Color(0xFF439462)
                                      : Colors.grey.shade400,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isSelected
                                              ? const Color(0xFF439462)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        addr.street,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        addr.details,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF439462)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showAddForm = true),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add New Address'),
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF439462)),
                      ),
                    ),
                  ] else ...[
                    if (addresses.isNotEmpty)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                setState(() => _showAddForm = false),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Text('Add New Address',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _buildAddressForm(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomAction(cart),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Label',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          Row(
            children: _labels.map((lbl) {
              bool isSelected = _selectedLabel == lbl['name'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLabel = lbl['name']),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF439462) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFF439462)
                              : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(lbl['icon'],
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 24),
                        const SizedBox(height: 4),
                        Text(
                          lbl['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
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
          Row(
            children: [
              const Expanded(
                  child: Text('Set as default address',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Switch.adaptive(
                value: _isDefault,
                activeTrackColor: const Color(0xFF439462),
                onChanged: (val) => setState(() => _isDefault = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_showAddForm)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439462),
                    foregroundColor: Colors.white),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address'),
              ),
            ),
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
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: const Color(0xFF439462),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF439462), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(CartProvider cart) {
    // If showing add form, bottom button is "Save Address", but we handled it in the form for clarity.
    // If not showing add form, bottom button is "Continue to Payment"
    if (_showAddForm || (cart.addresses.isEmpty)) {
      if (cart.addresses.isEmpty) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF439462),
                  foregroundColor: Colors.white),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Continue'),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
      ]),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PaymentMethodPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF439462),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue to Payment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
  const _StepDot(
      {required this.label,
      required this.stepIndex,
      required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final bool done = currentStep > stepIndex;
    final bool active = currentStep == stepIndex;
    final Color primary = const Color(0xFF38B24D);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (done || active) ? primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: (done || active) ? primary : Colors.grey.shade300,
                width: 2),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${stepIndex + 1}',
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight:
                    (done || active) ? FontWeight.bold : FontWeight.w500,
                color: (done || active) ? primary : Colors.grey.shade400)),
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
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
