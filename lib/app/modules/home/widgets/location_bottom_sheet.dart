import 'package:flutter/material.dart';
import '../../../data/services/db_service.dart';
import '../../../data/models/food_models.dart';
import '../../profile/view/address_form_page.dart';
import '../../location/view/select_delivery_address_screen.dart';

class LocationBottomSheet extends StatelessWidget {
  const LocationBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProviderScope.of(context);
    final addresses = cart.addresses;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Addresses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Add New Address Button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SelectDeliveryAddressScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xFF38B24D), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            color: Color(0xFF38B24D),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Saved Addresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (addresses.isEmpty)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 40),
                       child: Column(
                         children: [
                            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No saved addresses yet', style: TextStyle(color: Colors.grey)),
                         ],
                       ),
                     ),
                   )
                else
                  ...List.generate(addresses.length, (index) {
                    final addr = addresses[index];
                    final isSelected = cart.selectedAddressIndex == index;
                    return _buildAddressItem(context, cart, addr, index, isSelected);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(BuildContext context, CartProvider cart, UserAddress addr, int index, bool isSelected) {
    return InkWell(
      onTap: () {
        cart.selectAddress(index);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF38B24D).withOpacity(0.2) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  addr.title.toLowerCase() == 'home'
                      ? Icons.home_rounded
                      : Icons.location_on_rounded,
                  color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            addr.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '• 35 m',
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          if (isSelected) ...[
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFEBFFD7),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: const Text('Selected', style: TextStyle(color: Color(0xFF68B92E), fontSize: 10, fontWeight: FontWeight.w900)),
                             ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${addr.street}, ${addr.details}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
