import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/network/api_client.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/db_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../location/view/select_delivery_address_screen.dart';
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  bool _useProfileDetails = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CartProviderScope.of(context).loadAddresses();
      }
    });
  }

  @override
  void dispose() {
    _fullAddressCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isSaving = true);
    try {
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      if (loc != null) {
        final geo = ref.read(geocodingServiceProvider);
        final data =
            await geo.getAddressFromLatLng(loc.latitude, loc.longitude);
        if (!mounted) return;
        if (data != null) {
          _fullAddressCtrl.text = data['addressLine'] ?? '';
          _cityCtrl.text = data['city'] ?? '';
          _stateCtrl.text = data['state'] ?? '';
          _pincodeCtrl.text = data['postalCode'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Detect Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final cart = CartProviderScope.of(context);
      final service = cart.addressService!;

      String combinedAddress = '';
      if (_nameCtrl.text.trim().isNotEmpty)
        combinedAddress += 'Name: ${_nameCtrl.text.trim()}, ';
      if (_phoneCtrl.text.trim().isNotEmpty)
        combinedAddress += 'Phone: ${_phoneCtrl.text.trim()}, ';
      combinedAddress += _fullAddressCtrl.text.trim();

      final result = await service.saveAddress(
        label: _selectedLabel,
        fullAddress: combinedAddress,
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
            _fullAddressCtrl.clear();
            _cityCtrl.clear();
            _pincodeCtrl.clear();
            _stateCtrl.clear();
            _nameCtrl.clear();
            _phoneCtrl.clear();
          });
          
          // AUTO-NAVIGATE TO PAYMENT
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error: ${e is ApiException ? e.message : e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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

    // Auto-show form if no addresses exist is no longer needed since it's always shown

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () {
            if (_showAddForm && addresses.isNotEmpty) {
              setState(() => _showAddForm = false);
            } else {
              Navigator.pop(context);
            }
          },
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
          if (_showAddForm)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildAddAddressView(),
              ),
            )
          else ...[
            // TOP SECTION: Add new address actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Address',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showAddForm = true),
                          icon: const Icon(Icons.edit_location_alt_rounded,
                              size: 20, color: AppColors.accentGreen),
                          label: const Text('Add Manually',
                              style: TextStyle(
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side:
                                const BorderSide(color: AppColors.accentGreen),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showAddForm = true);
                            _detectLocation();
                          },
                          icon: const Icon(Icons.my_location,
                              size: 20, color: Colors.white),
                          label: const Text('Locate Me',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(
                height: 1, indent: 24, endIndent: 24, color: Colors.black12),

            // BOTTOM SECTION: Scrollable saved addresses list
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildAddressListView(cart),
              ),
            ),
          ],
          if (addresses.isNotEmpty && !_showAddForm) _buildBottomAction(cart),
        ],
      ),
    );
  }

  Widget _buildAddressListView(CartProvider cart) {
    final addresses = cart.addresses;
    return Container(
      key: const ValueKey('address_list'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Delivery Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final isSelected = cart.selectedAddressIndex == index;
                return _buildAddressCard(addr, isSelected, () {
                  cart.selectAddress(index);
                }, () {
                  cart.removeAddress(addr.id);
                }, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SelectDeliveryAddressScreen(
                              addressToEdit: addr))).then((_) => cart.loadAddresses());
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded,
                color: AppColors.accentGreen, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved addresses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Please add an address to continue with your order.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UserAddress addr, bool isSelected,
      VoidCallback onTap, VoidCallback onDelete, VoidCallback onEdit) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accentGreen.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentGreen.withValues(alpha: 0.1)
                    : const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                addr.title.toLowerCase() == 'home'
                    ? Icons.home_rounded
                    : addr.title.toLowerCase() == 'office'
                        ? Icons.work_rounded
                        : Icons.location_on_rounded,
                color:
                    isSelected ? AppColors.accentGreen : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        addr.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B2D1F),
                        ),
                      ),
                      if (addr.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addr.street,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    addr.details,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGreen
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.blueAccent, size: 22),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 22),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
    );
  }

  // removed _buildAddAddressButton

  Widget _buildAddAddressView() {
    return Padding(
      key: const ValueKey('add_form'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detect Location Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Address',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),
                TextButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location,
                      size: 18, color: AppColors.accentGreen),
                  label: const Text('Locate Me',
                      style: TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.accentGreen : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                        border: Border.all(
                            color: isSelected
                                ? AppColors.accentGreen
                                : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(lbl['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 26),
                          const SizedBox(height: 6),
                          Text(
                            lbl['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
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
            const SizedBox(height: 20),

            // Toggle for Profile Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Use my profile details',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1B2D1F))),
                Switch(
                  value: _useProfileDetails,
                  activeColor: AppColors.accentGreen,
                  activeTrackColor: const Color(0xFFEBFFD7),
                  onChanged: (v) {
                    setState(() {
                      _useProfileDetails = v;
                      if (v) {
                        final profile =
                            CartProviderScope.of(context).userProfile;
                        _nameCtrl.text =
                            profile.name != 'Guest User' ? profile.name : '';
                        String phone = profile.phone.trim();
                        if (phone.startsWith('+91')) {
                          phone = phone.substring(3).trim();
                        } else if (phone.startsWith('91') && phone.length > 10) {
                          phone = phone.substring(2).trim();
                        }
                        _phoneCtrl.text = phone;
                      } else {
                        _nameCtrl.clear();
                        _phoneCtrl.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _nameCtrl,
              label: 'Receiver Name',
              hint: 'John Doe',
              readOnly: _useProfileDetails,
              icon: Icons.person_outline,
              validator: (v) =>
                  v!.isEmpty ? 'Please enter receiver name' : null,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '10-digit mobile number',
              readOnly: _useProfileDetails,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter phone number';
                if (v.length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 20),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Field required';
                      if (v.length != 6) return 'Must be 6 digits';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _stateCtrl,
              label: 'State',
              hint: 'e.g. Uttar Pradesh',
              icon: Icons.holiday_village_rounded,
              validator: (v) => v!.isEmpty ? 'Please enter state' : null,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Set as default address',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDefault,
                    activeTrackColor:
                        AppColors.accentGreen.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.accentGreen,
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2D1F))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          cursorColor: AppColors.accentGreen,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PaymentMethodPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            elevation: 0,
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
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
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
    final Color primary = AppColors.accentGreen;

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
            color: active ? AppColors.accentGreen : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
