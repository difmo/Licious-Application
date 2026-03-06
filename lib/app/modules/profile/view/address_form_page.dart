import 'package:flutter/material.dart';
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
  late TextEditingController _streetCtrl;
  late TextEditingController _detailsCtrl;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.address?.title ?? '');
    _streetCtrl = TextEditingController(text: widget.address?.street ?? '');
    _detailsCtrl = TextEditingController(text: widget.address?.details ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _streetCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = CartProviderScope.of(context);
      final newAddress = UserAddress(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        details: _detailsCtrl.text.trim(),
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
                controller: _streetCtrl,
                label: 'Street / House No.',
                hint: '123 MG Road',
                icon: Icons.map_outlined,
                validator: (v) => v!.isEmpty ? 'Please enter street info' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _detailsCtrl,
                label: 'City, State, Pincode',
                hint: 'Lucknow, Uttar Pradesh 226001',
                icon: Icons.location_city_outlined,
                validator: (v) => v!.isEmpty ? 'Please enter details' : null,
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
              borderSide: BorderSide(color: Colors.grey.shade200),
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
