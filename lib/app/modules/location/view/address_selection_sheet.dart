import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/address_service.dart';
import 'location_map_picker.dart';
import 'address_details_screen.dart';

class AddressSelectionSheet extends ConsumerStatefulWidget {
  const AddressSelectionSheet({super.key});

  @override
  ConsumerState<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
  
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressSelectionSheet(),
    );
  }
}

class _AddressSelectionSheetState extends ConsumerState<AddressSelectionSheet> {
  bool _isLoading = true;
  List<dynamic> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(addressServiceProvider);
      final response = await service.getAddresses();
      if (response['success'] == true) {
        _addresses = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddNew() async {
     // Navigator.pop(context); // Close sheet
     final result = await Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => LocationMapPicker(
         onLocationSelected: (latLng, address) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddressDetailsScreen(locationData: {
                'lat': latLng.latitude,
                'lng': latLng.longitude,
                'address': address,
                // Add default placeholders for city/state if needed
              })),
            ).then((success) {
              if (success == true) _loadAddresses();
            });
         },
       )),
     );
     if (result != null) {
        _loadAddresses();
     }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select delivery address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1B2D1F))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : _addresses.isEmpty
                ? _buildEmptyState()
                : _buildAddressList(),
          ),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _onAddNew,
                     icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                     label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
                        side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.05), shape: BoxShape.circle),
             child: const Icon(Icons.location_off_rounded, color: AppColors.accentGreen, size: 48),
           ),
           const SizedBox(height: 16),
           const Text('No addresses yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           const SizedBox(height: 8),
           Text('Add an address to start ordering!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
         ],
       ),
     );
  }

  Widget _buildAddressList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final addr = _addresses[index];
        final String label = addr['label'] ?? 'Home';
        final String fullAddress = addr['fullAddress'] ?? '';
        final bool isDefault = addr['isDefault'] ?? false;

        return InkWell(
          onTap: () => Navigator.pop(context, addr),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(
                    label.toLowerCase() == 'home' ? Icons.home_rounded : 
                    label.toLowerCase() == 'office' || label.toLowerCase() == 'work' ? Icons.work_rounded : 
                    Icons.location_on_rounded, 
                    color: AppColors.accentGreen, size: 22
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isDefault) ...[
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(4)),
                               child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                             ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(fullAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}
