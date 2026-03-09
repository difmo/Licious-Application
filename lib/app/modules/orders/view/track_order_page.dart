import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/services/socket_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/services/notification_service.dart';

class TrackOrderPage extends ConsumerStatefulWidget {
  final String orderId;
  final Map<String, dynamic>? deliveryAddress;

  const TrackOrderPage({
    super.key,
    required this.orderId,
    this.deliveryAddress,
  });

  @override
  ConsumerState<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends ConsumerState<TrackOrderPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _riderLocation;
  LatLng? _deliveryLocation;
  String _status = "Preparing your order";
  bool _hasNotifiedProximity = false;

  @override
  void initState() {
    super.initState();
    _setupLocations();
    _connectSocket();
  }

  void _setupLocations() {
    // Attempt to parse delivery location if coordinates are available
    // For now, using a placeholder or default if not provided
    _deliveryLocation = const LatLng(26.8467, 80.9462); // Lucknow Default
    _markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation!,
        infoWindow: const InfoWindow(title: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _connectSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.joinOrderRoom(widget.orderId);

    socketService.onOrderUpdate((data) {
      if (mounted) {
        setState(() {
          final eventStatus = data['status'];
          final payload = data['data'];

          if (eventStatus == 'RIDER_LOCATION_UPDATE') {
            _riderLocation = LatLng(payload['lat'], payload['lng']);
            _updateRiderMarker(_riderLocation!);
            _checkProximity(_riderLocation!);
            _status = "Rider is on the way";
          } else if (eventStatus == 'DELIVERED') {
            _status = "Order Delivered!";
            _showDeliverySuccess();
          } else {
            _status = eventStatus.toString().replaceAll('_', ' ');
          }
        });
      }
    });
  }

  void _updateRiderMarker(LatLng location) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'rider');
      _markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: location,
          infoWindow: const InfoWindow(title: 'Rider Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });

    // Smoothly pan camera to show both markers if possible, or just follow rider
    _mapController.animateCamera(CameraUpdate.newLatLng(location));
  }

  void _checkProximity(LatLng riderPos) {
    if (_deliveryLocation == null || _hasNotifiedProximity) return;

    final double distance = Geolocator.distanceBetween(
      riderPos.latitude,
      riderPos.longitude,
      _deliveryLocation!.latitude,
      _deliveryLocation!.longitude,
    );

    if (distance < 500) {
      _hasNotifiedProximity = true;
      NotificationService.showNotification(
        id: widget.orderId.hashCode,
        title: 'Rider is nearby!',
        body: 'Your order is rotating around your corner. Get ready!',
      );
    }
  }

  void _showDeliverySuccess() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.accentGreen, size: 80),
            const SizedBox(height: 16),
            const Text('Delivered!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Your order has been successfully delivered. Hope you enjoy it!'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).leaveOrderRoom(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _deliveryLocation ?? const LatLng(26.8467, 80.9462),
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Floating Status Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.delivery_dining,
                            color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_status,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                                'Order ID: #${widget.orderId.substring(widget.orderId.length - 6)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
