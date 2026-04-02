import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../data/services/address_service.dart';
import '../../../data/services/db_service.dart';

import '../../../data/models/food_models.dart';

class SelectDeliveryAddressScreen extends ConsumerStatefulWidget {
  final UserAddress? addressToEdit;
  final bool isFromProfile;
  const SelectDeliveryAddressScreen({
    super.key,
    this.addressToEdit,
    this.isFromProfile = false,
  });

  @override
  ConsumerState<SelectDeliveryAddressScreen> createState() =>
      _SelectDeliveryAddressScreenState();
}

class _SelectDeliveryAddressScreenState
    extends ConsumerState<SelectDeliveryAddressScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _center;
  String _currentAddress = 'Locating...';
  String _locality = 'Fetching area...';
  String _city = 'Lucknow';
  String _state = 'UP';
  String _postalCode = '226010';

  // Form controllers
  String _selectedType = 'Home';
  bool _isSaving = false;
  bool _isEnteringDetails = false;
  bool _useProfileDetails = false;

  // Phase 3 Form Field controllers
  final _formKey = GlobalKey<FormState>();
  final _houseNoCtrl = TextEditingController();
  final _societyCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _parseEditAddress(widget.addressToEdit!);
    } else {
      _handleCurrentLocation();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.addressToEdit == null) {
        final profile = CartProviderScope.read(context).userProfile;
        if (profile.name != 'Guest User') {
          _nameCtrl.text = profile.name;
        }
        _pincodeCtrl.text = _postalCode;
      }
    });
  }

  void _parseEditAddress(UserAddress addr) {
    _isEnteringDetails = true;
    _selectedType = addr.title;

    String full = addr.street;

    final nameMatch = RegExp(r'Name:\s*([^,]+)').firstMatch(full);
    if (nameMatch != null) {
      _nameCtrl.text = nameMatch.group(1)!;
      full = full.replaceAll(nameMatch.group(0)!, '');
    }

    final phoneMatch = RegExp(r'Phone:\s*([^,]+)').firstMatch(full);
    if (phoneMatch != null) {
      _phoneCtrl.text = phoneMatch.group(1)!;
      full = full.replaceAll(phoneMatch.group(0)!, '');
    }

    final landmarkMatch = RegExp(r'Landmark:\s*([^,]+)').firstMatch(full);
    if (landmarkMatch != null) {
      _landmarkCtrl.text = landmarkMatch.group(1)!;
      full = full.replaceAll(landmarkMatch.group(0)!, '');
    }

    full = full
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r',\s*$'), '')
        .trim();
    if (full.startsWith(',')) full = full.substring(1).trim();

    final segments = full.split(',');
    if (segments.length > 1) {
      _houseNoCtrl.text = segments[0].trim();
      _societyCtrl.text = segments[1].trim();
      if (segments.length > 2) {
        _currentAddress = segments.sublist(2).join(', ').trim();
      } else {
        _currentAddress = '(Address locked for Edit Mode)';
      }
    } else {
      _houseNoCtrl.text = full;
      _societyCtrl.text = 'Previously Saved';
      _currentAddress = '(Address locked for Edit Mode)';
    }

    final cityParts = addr.details.split(',');
    _locality = cityParts.isNotEmpty ? cityParts.first : 'Area';
    _city = cityParts.isNotEmpty ? cityParts.first : 'City';
    _state = addr.details.contains(',') ? cityParts[1].trim() : '';
    _pincodeCtrl.text = addr.details.split(' ').last;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _houseNoCtrl.dispose();
    _societyCtrl.dispose();
    _landmarkCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pincodeCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // refresh syntax for clear button
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      if (mounted) setState(() => _predictions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final geoService = ref.read(geocodingServiceProvider);
      final results = await geoService.getPlacePredictions(query);
      if (mounted) {
        setState(() {
          _predictions = results;
        });
      }
    });
  }

  Future<void> _onPredictionTapped(Map<String, dynamic> prediction) async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() {
      _predictions = [];
      _searchController.text =
          prediction['mainText'] ?? prediction['description'];
    });

    final geoService = ref.read(geocodingServiceProvider);
    final details = await geoService.getPlaceDetails(prediction['placeId']);

    if (details != null && mounted) {
      final lat = details['latitude'];
      final lng = details['longitude'];
      if (lat != null && lng != null) {
        _center = LatLng(lat, lng);
        final controller = await _mapController.future;
        if (!mounted) return;
        controller.animateCamera(CameraUpdate.newLatLngZoom(_center!, 17));
        _reverseGeocode(_center!);
      }
    }
  }

  Future<void> _handleCurrentLocation() async {
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentLocation();
      if (pos != null) {
        _center = LatLng(pos.latitude, pos.longitude);
        final controller = await _mapController.future;
        if (!mounted) return;
        // moveCamera forces the jump instantly without waiting for animation frames
        controller.moveCamera(CameraUpdate.newLatLngZoom(_center!, 17));
        _reverseGeocode(_center!);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please enable GPS/Location in your device settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    final geoService = ref.read(geocodingServiceProvider);
    final data = await geoService.getAddressFromLatLng(
        location.latitude, location.longitude);
    if (mounted) {
      setState(() {
        if (data != null) {
          _locality = data['city']?.isNotEmpty == true
              ? data['city']!
              : 'Selected Area';
          _currentAddress = data['addressLine']?.isNotEmpty == true
              ? data['addressLine']!
              : 'Unknown Location';
          _city = data['city']?.isNotEmpty == true ? data['city']! : 'Lucknow';
          _state = data['state']?.isNotEmpty == true ? data['state']! : 'UP';
          _postalCode = data['postalCode']?.isNotEmpty == true
              ? data['postalCode']!
              : '226010';
          _pincodeCtrl.text = _postalCode;
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

  void _onConfirm() {
    if (_center == null) return;
    if (_currentAddress == 'Locating...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait for the exact address to load'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isEnteringDetails = true);
  }

  Future<void> _saveFinalAddress() async {
    if (!_formKey.currentState!.validate()) return;

    // CAPTURE context-dependent references BEFORE any await
    final cartProvider = CartProviderScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      final service = ref.read(addressServiceProvider);

      // Combine manual data with geocoded data
      String combinedAddress =
          '${_houseNoCtrl.text.trim()}, ${_societyCtrl.text.trim()}';
      if (_landmarkCtrl.text.trim().isNotEmpty) {
        combinedAddress += ', Landmark: ${_landmarkCtrl.text.trim()}';
      }
      combinedAddress += ', Name: ${_nameCtrl.text.trim()}';
      combinedAddress += ', Phone: ${_phoneCtrl.text.trim()}';
      if (_currentAddress != '(Address locked for Edit Mode)') {
        combinedAddress += ', $_currentAddress';
      }

      Map<String, dynamic> response;
      if (widget.addressToEdit != null) {
        response = await service.updateAddress(widget.addressToEdit!.id, {
          "label": _selectedType,
          "fullAddress": combinedAddress,
          "city": _city,
          "state": _state,
          "pincode": _pincodeCtrl.text.trim(),
          "isDefault": widget.addressToEdit!.isDefault,
        });
      } else {
        response = await service.saveAddress(
          label: _selectedType,
          fullAddress: combinedAddress,
          city: _city,
          state: _state,
          pincode: _pincodeCtrl.text.trim(),
          isDefault: true,
        );
      }

      final bool isSuccessful = response['success'] == true || 
                               response.containsKey('_id') || 
                               response.containsKey('id') || 
                               response.containsKey('data');

      if (isSuccessful) {
        // Refresh local addresses
        await cartProvider.loadAddresses();
        
        if (!widget.isFromProfile && widget.addressToEdit == null) {
          cartProvider.selectAddress(0); // Auto-select the newly added address
        }

        if (mounted) {
          // Small delay to let state settle
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
             navigator.pop(true);
          }
        }
      } else {
        // Handle explicit success=false
        if (mounted) {
          final msg = response['message']?.toString() ?? 'Failed to save address. Please try again.';
          messenger.showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
          style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w900,
              fontSize: 18),
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
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for apartment, street name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isEnteringDetails ? _buildSplitView() : _buildMapPickerView(),
    );
  }

  Widget _buildMapPickerView() {
    return Stack(
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
          myLocationButtonEnabled:
              false, // We use a custom button so it's not hidden
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B23),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Order will be delivered here',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A)),
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
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38B24D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Enter Address Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Custom highly-visible My Location Button
        Positioned(
          bottom: 240,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'select_loc_fab',
            backgroundColor: Colors.white,
            onPressed: _handleCurrentLocation,
            child: const Icon(Icons.my_location,
                color: Colors.blueAccent, size: 28),
          ),
        ),

        // ── Search Results Dropdown ───────────────────────────────────────
        if (_predictions.isNotEmpty)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final pred = _predictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: Colors.grey),
                      title: Text(pred['mainText'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(pred['secondaryText'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      onTap: () => _onPredictionTapped(pred),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplitView() {
    return Column(
      children: [
        // Phase 2: Top 30% Non-interactive Map Preview
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center ?? const LatLng(26.8467, 80.9462),
                  zoom: 17,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                markers: {
                  if (_center != null)
                    Marker(
                      markerId: const MarkerId('pinned'),
                      position: _center!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                    ),
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _isEnteringDetails = false),
                  icon: const Icon(Icons.edit_location_alt,
                      size: 16, color: Colors.blueAccent),
                  label: const Text('Change',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black38,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Phase 2: Bottom 70% Scrollable Form Container
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Save Delivery Address',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),

                    // Phase 3: Pinned Address Field (Read-Only)
                    TextFormField(
                      initialValue: _currentAddress,
                      readOnly: true, // Prevents generic edits
                      maxLines: 2,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Pinned GPS Location',
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentGreen),
                        filled: true,
                        fillColor:
                            Colors.grey.shade100, // Distinct grey background
                        prefixIcon: const Icon(Icons.gps_fixed,
                            color: AppColors.accentGreen),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phase 3: Building / House Number (Mandatory)
                    TextFormField(
                      controller: _houseNoCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'House / Flat / Block No. *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Building / Society Name (Mandatory)
                    TextFormField(
                      controller: _societyCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Apartment / Society Name *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Landmark (Optional)
                    TextFormField(
                      controller: _landmarkCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Landmark (Optional)',
                        hintText: 'e.g. Near Apollo Hospital',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Pincode (Numeric, 6 Digits)
                    TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Pincode *',
                        hintText: '6-digit pincode',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.pin_drop_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 6) return 'Must be 6 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Toggle for Profile Data
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Use my profile details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A))),
                        Switch(
                          value: _useProfileDetails,
                          activeColor: AppColors.accentGreen,
                          activeTrackColor: const Color(0xFFEBFFD7),
                          onChanged: (v) {
                            setState(() {
                              _useProfileDetails = v;
                              if (v) {
                                if (!mounted) return;
                                final profile =
                                    CartProviderScope.read(context).userProfile;
                                _nameCtrl.text = profile.name != 'Guest User'
                                    ? profile.name
                                    : '';
                                String phone = profile.phone.trim();
                                if (phone.startsWith('+91')) {
                                  phone = phone.substring(3).trim();
                                } else if (phone.startsWith('91') && phone.length > 10) {
                                  phone = phone.substring(2).trim();
                                }
                                _phoneCtrl.text = phone;
                              } else {
                                if (widget.addressToEdit == null) {
                                  _nameCtrl.clear();
                                  _phoneCtrl.clear();
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Receiver Name (Mandatory)
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      readOnly: _useProfileDetails,
                      decoration: InputDecoration(
                        labelText: 'Receiver Name *',
                        filled: true,
                        fillColor: _useProfileDetails
                            ? Colors.grey.shade100
                            : Colors.white,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _useProfileDetails ? Colors.grey.shade400 : AppColors.accentGreen,
                              width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phase 3: Phone Number (Numeric, 10 Digits)
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      readOnly: _useProfileDetails,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveFinalAddress(),
                      decoration: InputDecoration(
                        labelText: 'Receiver Phone Number *',
                        filled: true,
                        fillColor: _useProfileDetails
                            ? Colors.grey.shade100
                            : Colors.white,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _useProfileDetails ? Colors.grey.shade400 : AppColors.accentGreen,
                              width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length != 10) return 'Must be 10 digits';
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // Phase 4: Save Address Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveFinalAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Save Delivery Address',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
