import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../data/services/address_service.dart';
import '../../../data/services/db_service.dart';

class SelectDeliveryAddressScreen extends ConsumerStatefulWidget {
  const SelectDeliveryAddressScreen({super.key});

  @override
  ConsumerState<SelectDeliveryAddressScreen> createState() => _SelectDeliveryAddressScreenState();
}

class _SelectDeliveryAddressScreenState extends ConsumerState<SelectDeliveryAddressScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _center;
  String _currentAddress = 'Locating...';
  String _locality = 'Fetching area...';
  
  // Form controllers
  String _selectedType = 'Home';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _handleCurrentLocation();
  }

  Future<void> _handleCurrentLocation() async {
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentLocation();
      if (pos != null) {
        _center = LatLng(pos.latitude, pos.longitude);
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(_center!, 17));
        _reverseGeocode(_center!);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    final geoService = ref.read(geocodingServiceProvider);
    final data = await geoService.getAddressFromLatLng(location.latitude, location.longitude);
    if (mounted) {
      setState(() {
        if (data != null) {
          _locality = data['city']?.isNotEmpty == true ? data['city']! : 'Selected Area';
          _currentAddress = data['addressLine']?.isNotEmpty == true ? data['addressLine']! : 'Unknown Location';
        } else {
          _locality = 'Location API Error';
          _currentAddress = 'Check Maps API key and billing in Google Cloud';
        }
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }

  void _onCameraIdle() {
    if (_center != null) _reverseGeocode(_center!);
  }

  Future<void> _onConfirm() async {
    if (_center == null) return;
    
    setState(() => _isSaving = true);
    try {
      final service = ref.read(addressServiceProvider);
      final response = await service.saveAddress(
        label: _selectedType,
        fullAddress: _currentAddress,
        city: 'Lucknow',
        state: 'UP',
        pincode: '226010',
        isDefault: true,
      );

      if (mounted && response['success'] == true) {
        // Refresh local addresses
        final cart = CartProviderScope.of(context);
        await cart.loadAddresses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address Saved!'), backgroundColor: AppColors.accentGreen),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Your Location',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for apartment, street name...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Map Section ───────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(26.8467, 80.9462),
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController.complete(c),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // ── Central Pin + Tooltip ──────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tooltip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B23),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Order will be delivered here',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Place the pin to your exact location',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Tooltip arrow
                Container(
                   width: 10,
                   height: 10,
                   transform: Matrix4.translationValues(0, -5, 0)..rotateZ(0.785),
                   color: const Color(0xFF1A1B23),
                ),
                const SizedBox(height: 4),
                // Pin
                const Icon(Icons.location_on, color: Color(0xFF38B24D), size: 40),
              ],
            ),
          ),

          // ── Bottom Section ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locality,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAddress,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38B24D), // Matching image's pink, or user can change to primary
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Re-center button
          Positioned(
            bottom: 220,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _handleCurrentLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF38B24D)),
            ),
          ),
        ],
      ),
    );
  }
}
