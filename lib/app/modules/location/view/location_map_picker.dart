import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';

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
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);
    try {
      if (widget.initialLocation != null) {
        _center = widget.initialLocation;
      } else {
        final pos = await ref.read(locationServiceProvider).getCurrentLocation();
        if (pos != null) {
          _center = LatLng(pos.latitude, pos.longitude);
        } else {
          _center = const LatLng(26.8467, 80.9462); // Default to Lucknow
        }
      }
      await _reverseGeocode(_center!);
    } catch (e) {
      _center = const LatLng(26.8467, 80.9462);
      _currentAddress = 'Location permission denied. Map centered on Lucknow.';
    } finally {
      setState(() => _isLocating = false);
      if (_center != null) {
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(_center!, 17));
      }
    }
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
          // The Map
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
          ),

          // Central Pin
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
                          // Default manual navigation if callback not provided
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
