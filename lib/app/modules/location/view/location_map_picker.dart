import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../widgets/common_button.dart';

class LocationMapPicker extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String)? onLocationSelected;

  const LocationMapPicker({
    super.key,
    this.initialLocation,
    this.onLocationSelected,
  });

  @override
  ConsumerState<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends ConsumerState<LocationMapPicker> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _center;
  String _currentAddress = 'Fetching address...';
  bool _isMoving = false;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    // Default center to Lucknow while checking
    _center = widget.initialLocation ?? const LatLng(26.8467, 80.9462);
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);
    
    try {
      if (widget.initialLocation != null) {
        _center = widget.initialLocation;
      } else {
        // [CONTEXTUAL FLOW] Check permission state first
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (permission == LocationPermission.denied) {
          // Show our custom explanation sheet BEFORE system prompt
          final granted = await _showPermissionExplanation();
          if (!granted) {
             _center = const LatLng(26.8467, 80.9462); 
             setState(() => _isLocating = false);
             return;
          }
        } else if (permission == LocationPermission.deniedForever) {
          _showPermanentlyDeniedDialog();
          _center = const LatLng(26.8467, 80.9462);
          setState(() => _isLocating = false);
          return;
        }

        // If granted/just-granted, fetch position
        final pos = await ref.read(locationServiceProvider).getCurrentLocation();
        if (pos != null) {
          _center = LatLng(pos.latitude, pos.longitude);
        }
      }
      
      if (_center != null) await _reverseGeocode(_center!);
      
    } catch (e) {
      debugPrint('Location fetching error: $e');
      _center = const LatLng(26.8467, 80.9462);
      _currentAddress = 'Could not fetch location automatically.';
    } finally {
      setState(() => _isLocating = false);
      if (_center != null) {
        try {
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(_center!, 17));
        } catch (e) {
          debugPrint('Map controller not ready: $e');
        }
      }
    }
  }

  Future<bool> _showPermissionExplanation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, size: 40, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Allow Location Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 12),
            const Text(
              'We use your location to accurately find your address for faster delivery and store discovery.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            CommonButton(
              text: 'CONTINUE',
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Enter Address Manually', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == true) {
       final status = await Geolocator.requestPermission();
       return status == LocationPermission.always || status == LocationPermission.whileInUse;
    }
    return false;
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access'),
        content: const Text(
          'Location access is permanently disabled for this app. Please enable it in Settings to detect your location automatically.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('SETTINGS'),
          ),
        ],
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng location) async {
    final geoService = ref.read(geocodingServiceProvider);
    final data = await geoService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );
    if (mounted) {
      setState(() {
        _currentAddress = data?['addressLine'] ?? 'Unknown location';
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    if (!_isMoving) {
      setState(() => _isMoving = true);
    }
  }

  void _onCameraIdle() async {
    setState(() => _isMoving = false);
    if (_center != null) {
      await _reverseGeocode(_center!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center ?? const LatLng(26.8467, 80.9462),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onTap: (latLng) {
               // Optional: allow tapping to place pin
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isMoving ? -10 : 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 30),
                    ),
                    Container(
                      width: 4,
                      height: 10,
                      color: AppColors.accentGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Box (Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                   const Icon(Icons.search_rounded, color: Colors.grey),
                   const SizedBox(width: 12),
                   Text(
                     'Search for area, street...',
                     style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                   ),
                ],
              ),
            ),
          ),

          // Bottom Detail Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select delivery location',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.accentGreen, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                                _center != null ? 'Selected Area' : 'Locating...',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               _currentAddress,
                               style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLocating ? null : () {
                        if (widget.onLocationSelected != null && _center != null) {
                          widget.onLocationSelected!(_center!, _currentAddress);
                        } else {
                           Navigator.pop(context, {'lat': _center!.latitude, 'lng': _center!.longitude, 'address': _currentAddress});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 220,
            right: 20,
            child: FloatingActionButton(
              onPressed: _initLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accentGreen,
              mini: true,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
