import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/core/constants/app_colors.dart';
import '../../../../app/data/services/address_service.dart';

class AddressDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> locationData;

  const AddressDetailsScreen({super.key, required this.locationData});

  @override
  ConsumerState<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends ConsumerState<AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _flatNoCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  
  String _selectedType = 'Home';
  bool _isDefault = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _types = [
    {'name': 'Home', 'icon': Icons.home_rounded},
    {'name': 'Office', 'icon': Icons.work_rounded},
    {'name': 'Other', 'icon': Icons.location_on_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize locality from locationData if available
    _localityCtrl.text = widget.locationData['address'] ?? '';
  }

  @override
  void dispose() {
    _flatNoCtrl.dispose();
    _floorCtrl.dispose();
    _landmarkCtrl.dispose();
    _localityCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final service = ref.read(addressServiceProvider);
      
      // Construct full address string or separate data depending on API
      final fullAddress = "${_flatNoCtrl.text}, ${_floorCtrl.text.isNotEmpty ? 'Floor ${_floorCtrl.text}, ' : ''}${_localityCtrl.text}";
      
      await service.saveAddress(
        label: _selectedType,
        fullAddress: fullAddress,
        city: widget.locationData['city'] ?? 'Lucknow',
        state: widget.locationData['state'] ?? 'UP',
        pincode: widget.locationData['pincode'] ?? '226010',
        isDefault: _isDefault,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Address saved successfully!'), backgroundColor: AppColors.accentGreen),
        );
        // Pop all the way back or navigate to checkout
        Navigator.pop(context, true);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Address Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location Confirmed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(_localityCtrl.text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('ADDRESS INFO', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 16),

              _buildField(
                controller: _flatNoCtrl,
                label: 'Flat / House / Office No.',
                required: true,
                icon: Icons.store_rounded,
              ),
              const SizedBox(height: 20),

              _buildField(
                controller: _floorCtrl,
                label: 'Floor (Optional)',
                icon: Icons.layers_rounded,
              ),
              const SizedBox(height: 20),

              _buildField(
                controller: _landmarkCtrl,
                label: 'Landmark',
                hint: 'Nearby school, hospital, etc.',
                required: true,
                icon: Icons.assistant_photo_rounded,
              ),
              const SizedBox(height: 32),

              const Text('SAVE AS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 16),

              Row(
                children: _types.map((type) {
                  bool isSelected = _selectedType == type['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type['name']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentGreen : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.accentGreen : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(type['icon'], color: isSelected ? Colors.white : Colors.grey.shade600, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              type['name'],
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
              
              // Default switch
              ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: const Text('Set as default address', style: TextStyle(fontWeight: FontWeight.w600)),
                 trailing: Switch.adaptive(
                    value: _isDefault, 
                    activeColor: AppColors.accentGreen,
                    onChanged: (v) => setState(() => _isDefault = v),
                 ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, String? hint, bool required = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required field' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
      ),
    );
  }
}
