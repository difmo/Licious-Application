import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/food_models.dart';
import '../../../data/services/db_service.dart';

class AddressFormPage extends StatefulWidget {
  final UserAddress? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    String tempStreet = widget.address?.street ?? '';
    final nameMatch = RegExp(r'Name:\s*([^,]+)').firstMatch(tempStreet);
    String name = '';
    if (nameMatch != null) {
      name = nameMatch.group(1)!;
      tempStreet = tempStreet.replaceAll('${nameMatch.group(0)!}, ', '').replaceAll(nameMatch.group(0)!, '');
    }
    final phoneMatch = RegExp(r'Phone:\s*([^,]+)').firstMatch(tempStreet);
    String phone = '';
    if (phoneMatch != null) {
      phone = phoneMatch.group(1)!;
      tempStreet = tempStreet.replaceAll('${phoneMatch.group(0)!}, ', '').replaceAll(phoneMatch.group(0)!, '');
    }

    _titleCtrl = TextEditingController(text: widget.address?.title ?? '');
    _nameCtrl = TextEditingController(text: name);
    _phoneCtrl = TextEditingController(text: phone);
    _streetCtrl = TextEditingController(text: tempStreet.trim());
    
    // Parse details: "City, State Pincode" or similar
    String city = '';
    String state = '';
    String pincode = '';
    final details = widget.address?.details ?? '';
    if (details.isNotEmpty) {
      final parts = details.split(',');
      if (parts.length >= 2) {
        city = parts[0].trim();
        final statePin = parts[1].trim();
        final lastSpace = statePin.lastIndexOf(' ');
        if (lastSpace != -1) {
          state = statePin.substring(0, lastSpace).trim();
          pincode = statePin.substring(lastSpace + 1).trim();
        } else {
          state = statePin;
        }
      } else {
        city = details;
      }
    }

    _cityCtrl = TextEditingController(text: city);
    _stateCtrl = TextEditingController(text: state);
    _pincodeCtrl = TextEditingController(text: pincode);
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = CartProviderScope.of(context);
      
      String combinedStreet = '';
      if (_nameCtrl.text.trim().isNotEmpty) combinedStreet += 'Name: ${_nameCtrl.text.trim()}, ';
      if (_phoneCtrl.text.trim().isNotEmpty) combinedStreet += 'Phone: ${_phoneCtrl.text.trim()}, ';
      combinedStreet += _streetCtrl.text.trim();

      final newAddress = UserAddress(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        street: combinedStreet,
        details: '${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} ${_pincodeCtrl.text.trim()}',
        isDefault: _isDefault,
      );

      if (widget.address == null) {
        provider.addAddress(newAddress);
      } else {
        provider.updateAddress(newAddress);
      }
      Navigator.pop(context);
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
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _titleCtrl,
                label: 'Label',
                hint: 'Home, Office, etc.',
                icon: Icons.label_outline,
                validator: (v) => v!.isEmpty ? 'Please enter a label' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _nameCtrl,
                label: 'Receiver Name',
                hint: 'John Doe',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Please enter receiver name' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '10-digit mobile number',
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
              const SizedBox(height: 16),
              _buildField(
                controller: _streetCtrl,
                label: 'Street / House No.',
                hint: '123 MG Road',
                icon: Icons.map_outlined,
                validator: (v) => v!.isEmpty ? 'Please enter street info' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Lucknow',
                      icon: Icons.location_city_outlined,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _stateCtrl,
                      label: 'State',
                      hint: 'UP',
                      icon: Icons.map,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _pincodeCtrl,
                label: 'Pincode',
                hint: '6-digit pincode',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter pincode';
                  if (v.length != 6) return 'Must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    activeThumbColor: const Color(0xFF68B92E),
                    activeTrackColor: const Color(0xFFEBFFD7),
                  ),
                  const Text(
                    'Set as default address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439462),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 22, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF439462), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF439462)),
            ),
          ),
        ),
      ],
    );
  }
}
