import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  /// Optional initial coordinate to center the map on.
  /// If null, it will default to the user's current location.
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  // Map Controller
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  
  // State variables for selection
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  
  // States
  bool _isLoading = true;
  bool _isMapLoading = false;
  String? _errorMessage;

  // Controllers for address fields
  final TextEditingController _addressLineCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _postalCodeCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  // Default fallback location (e.g., center of a relevant city)
  static const LatLng _defaultFallbackLocation = LatLng(26.8467, 80.9462); // Lucknow

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _addressLineCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCodeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.initialLocation != null) {
        // Use supplied initial location
        await _updateSelectedLocation(widget.initialLocation!);
      } else {
        // Fetch real-time GPS
        final locService = ref.read(locationServiceProvider);
        final position = await locService.getCurrentLocation();
        
        if (position != null) {
          final latLng = LatLng(position.latitude, position.longitude);
          await _updateSelectedLocation(latLng);
        } else {
          // Fallback if null pos (rare)
          await _updateSelectedLocation(_defaultFallbackLocation);
        }
      }
    } catch (e) {
      // Permission denied or services disabled
      setState(() {
        _errorMessage = e.toString();
        // Still set a fallback so the map can render
        _selectedLocation = _defaultFallbackLocation;
      });
      _updateMarker(_defaultFallbackLocation);
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Move camera if map is already initialized
      if (_selectedLocation != null) {
        _moveCamera(_selectedLocation!);
      }
    }
  }

  Future<void> _updateSelectedLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isMapLoading = true;
    });

    // Update lat/lng fields immediately
    _latCtrl.text = location.latitude.toString();
    _lngCtrl.text = location.longitude.toString();

    // Move map marker
    _updateMarker(location);
    _moveCamera(location);

    // Call geocoding service to fetch address
    final geoService = ref.read(geocodingServiceProvider);
    final addressData = await geoService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    if (addressData != null && mounted) {
      setState(() {
        _addressLineCtrl.text = addressData['addressLine'] ?? '';
        _cityCtrl.text = addressData['city'] ?? '';
        _stateCtrl.text = addressData['state'] ?? '';
        _postalCodeCtrl.text = addressData['postalCode'] ?? '';
      });
    }

    if (mounted) {
      setState(() {
        _isMapLoading = false;
      });
    }
  }

  void _updateMarker(LatLng pos) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Selected Delivery Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  Future<void> _moveCamera(LatLng pos) async {
    if (_mapControllerCompleter.isCompleted) {
      final controller = await _mapControllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 16.5));
    }
  }

  void _onMapTapped(LatLng position) {
    _updateSelectedLocation(position);
  }

  void _handleConfirm() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    final resultData = {
      'addressLine': _addressLineCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'postalCode': _postalCodeCtrl.text.trim(),
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    };

    // Return the selected location and address details
    Navigator.pop(context, resultData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : Column(
              children: [
                // ── Map Section (Flexible) ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? _defaultFallbackLocation,
                          zoom: 15.0,
                        ),
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          if (!_mapControllerCompleter.isCompleted) {
                            _mapControllerCompleter.complete(controller);
                          }
                          _mapController = controller;
                        },
                        onTap: _onMapTapped,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      
                      if (_isMapLoading)
                        const Positioned(
                          top: 20,
                          right: 20,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ),
                        ),

                      // Floating "My Location" Button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: 'map_my_loc',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accentGreen,
                          onPressed: _initLocation,
                          child: const Icon(Icons.my_location_rounded, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Error Message Banner ──────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.red.shade50,
                    child: Text(
                      'Could not get GPS location. You can still pick a point manually.\nError: $_errorMessage',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                    ),
                  ),

                // ── Address Fields Section (Flexible) ─────────────────────
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        )
                      ],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: AppColors.accentGreen, size: 20),
                              SizedBox(width: 8),
                              Text('Address Details',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildTextField(
                            controller: _addressLineCtrl,
                            label: 'Address Line',
                            hint: 'Street, House No, Landmark',
                            icon: Icons.edit_road_rounded,
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _cityCtrl,
                                  label: 'City',
                                  icon: Icons.location_city_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _stateCtrl,
                                  label: 'State',
                                  icon: Icons.map_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          _buildTextField(
                            controller: _postalCodeCtrl,
                            label: 'Postal Code',
                            icon: Icons.markunread_mailbox_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          // Coordinates (Read Only)
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _latCtrl,
                                  label: 'Latitude',
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _lngCtrl,
                                  label: 'Longitude',
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // ── Action Buttons ────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _initLocation,
                                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                                  label: const Text('Current Loc', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentGreen,
                                    side: const BorderSide(color: AppColors.accentGreen),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _handleConfirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w500,
        color: readOnly ? Colors.grey.shade700 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey.shade500) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGreen),
        ),
      ),
    );
  }
}
