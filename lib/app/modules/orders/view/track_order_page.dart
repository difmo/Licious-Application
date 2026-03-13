import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/services/socket_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/order_service.dart';

/// Maps every backend status string → a 0-based step index (0 = just placed).
int _statusToStep(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 0;
    case 'accepted':
      return 1;
    case 'pickedup':
    case 'picked_up':
    case 'out_for_delivery':
    case 'out for delivery':
    case 'ontheway':
      return 2;
    case 'delivered':
      return 3;
    default:
      return 0;
  }
}

String _stepLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Order Placed';
    case 'accepted':
      return 'Accepted by Rider';
    case 'pickedup':
    case 'picked_up':
    case 'out_for_delivery':
    case 'out for delivery':
    case 'ontheway':
      return 'Out for Delivery';
    case 'delivered':
      return 'Delivered!';
    default:
      return status;
  }
}

class TrackOrderPage extends ConsumerStatefulWidget {
  final String orderId;
  final Map<String, dynamic>? deliveryAddress;
  final String? status; // initial status passed from card

  const TrackOrderPage({
    super.key,
    required this.orderId,
    this.deliveryAddress,
    this.status,
  });

  @override
  ConsumerState<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends ConsumerState<TrackOrderPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _riderLocation;
  LatLng? _deliveryLocation;

  // Live order state
  late String _currentStatus;
  String _riderName = '';
  String _riderPhone = '';
  bool _hasNotifiedProximity = false;
  bool _isLoading = true;

  // Socket callbacks
  late void Function(dynamic) _onOrderUpdate;
  late void Function(dynamic) _onRiderAssigned;

  // Pulse animation for the live dot
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status ?? 'Pending';
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _setupLocations();
    _fetchOrderDetails();
    _connectSocket();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderData =
          await ref.read(orderServiceProvider).getOrderById(widget.orderId);
      if (!mounted) return;
      if (orderData.isNotEmpty) {
        setState(() {
          _currentStatus = orderData['status']?.toString() ?? _currentStatus;
          final rider = orderData['rider'] ?? orderData['riderId'];
          if (rider is Map) {
            _riderName = rider['fullName'] ?? rider['name'] ?? _riderName;
            _riderPhone = rider['phoneNumber'] ?? rider['phone'] ?? _riderPhone;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupLocations() {
    final addr = widget.deliveryAddress;
    if (addr != null) {
      final lat = (addr['lat'] ??
          addr['latitude'] ??
          addr['coordinates']?['lat'] ??
          26.8467) as num;
      final lng = (addr['lng'] ??
          addr['longitude'] ??
          addr['coordinates']?['lng'] ??
          80.9462) as num;
      _deliveryLocation = LatLng(lat.toDouble(), lng.toDouble());
    } else {
      _deliveryLocation = const LatLng(26.8467, 80.9462); // Lucknow default
    }
    _updateMarkers();
  }

  void _updateMarkers() {
    _markers.clear();
    if (_deliveryLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation!,
        infoWindow: const InfoWindow(title: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    if (_riderLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderLocation!,
        infoWindow: const InfoWindow(title: 'Delivery Rider'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (mounted) setState(() {});
  }

  void _connectSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.joinOrderRoom(widget.orderId);

    _onOrderUpdate = (data) {
      if (!mounted) return;
      final String statusStr = (data['status'] ?? '').toString();
      final payload = data['data'];

      // Handle Rider Location Change specifically
      if (statusStr == 'RIDER_LOCATION_UPDATE') {
        if (payload is Map &&
            payload['lat'] != null &&
            payload['lng'] != null) {
          final lat = (payload['lat'] as num).toDouble();
          final lng = (payload['lng'] as num).toDouble();
          debugPrint('📍 Rider moving: $lat, $lng');
          setState(() {
            _riderLocation = LatLng(lat, lng);
            _updateMarkers();
          });
          _checkProximity(_riderLocation!);
        }
        return;
      }

      // Handle Status Change
      setState(() {
        if (statusStr.isNotEmpty && statusStr != 'RIDER_LOCATION_UPDATE') {
          _currentStatus = statusStr;
        }

        if (payload is Map) {
          // If the payload has the full order object, extract rider
          final rider = payload['rider'] ?? payload['riderId'];
          if (rider is Map) {
            _riderName = rider['fullName'] ?? rider['name'] ?? _riderName;
            _riderPhone = rider['phoneNumber'] ?? rider['phone'] ?? _riderPhone;
          }
        }
      });

      if (statusStr.toLowerCase() == 'delivered') {
        Future.delayed(const Duration(milliseconds: 500), _showDeliverySuccess);
      }
    };

    _onRiderAssigned = (data) {
      if (!mounted) return;
      debugPrint('🛵 Rider assigned: ${data['riderName']}');
      setState(() {
        _riderName = data['riderName']?.toString() ?? _riderName;
        _riderPhone = data['riderPhone']?.toString() ?? _riderPhone;
        if (_currentStatus.toLowerCase() == 'pending') {
          _currentStatus = 'Accepted';
        }
      });
    };

    socketService.onOrderUpdate(_onOrderUpdate);
    socketService.onRiderAssigned(_onRiderAssigned);
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
        title: '🛵 Rider is nearby!',
        body: 'Your order will arrive in a few minutes. Get ready!',
      );
    }
  }

  void _showDeliverySuccess() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF68B92E), size: 72),
            const SizedBox(height: 16),
            const Text('Order Delivered!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 8),
            const Text('Enjoy your fresh shrimp! 🦐',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to active orders
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF114F3B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    final socketService = ref.read(socketServiceProvider);
    socketService.leaveOrderRoom(widget.orderId);
    socketService.offOrderUpdate(_onOrderUpdate);
    socketService.offRiderAssigned(_onRiderAssigned);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _statusToStep(_currentStatus);
    final shortId = widget.orderId.length > 8
        ? '#${widget.orderId.substring(widget.orderId.length - 8).toUpperCase()}'
        : '#${widget.orderId.toUpperCase()}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Track Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _deliveryLocation ?? const LatLng(26.8467, 80.9462),
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF114F3B)),
              ),
            ),

          // ── Bottom Sheet ────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.52,
            minChildSize: 0.18,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Live Status Header ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Live pulse dot
                                  AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, __) => Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                            alpha: _pulseAnim.value),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('LIVE',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _stepLabel(_currentStatus),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: -0.5),
                              ),
                              Text(
                                _getStatusSubtitle(_currentStatus),
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F4EC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.timer_outlined,
                                  color: Color(0xFF114F3B), size: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(shortId,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Stepper ────────────────────────────────────────────
                    _buildStepper(step),

                    const SizedBox(height: 28),
                    Divider(color: Colors.grey.shade100, thickness: 1.5),
                    const SizedBox(height: 20),

                    // ── Delivery Address ───────────────────────────────────
                    _buildAddressCard(),

                    const SizedBox(height: 16),

                    // ── Rider Info ─────────────────────────────────────────
                    if (step >= 1) _buildRiderCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    final steps = [
      {'label': 'Order Placed', 'icon': Icons.check_circle_outline},
      {'label': 'Accepted by Rider', 'icon': Icons.delivery_dining},
      {'label': 'Out for Delivery', 'icon': Icons.electric_bolt},
      {'label': 'Delivered', 'icon': Icons.home_rounded},
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i <= currentStep;
        final isCurrent = i == currentStep;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + line
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF114F3B)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                  color: const Color(0xFF114F3B)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: Icon(
                      isDone ? Icons.check : (steps[i]['icon'] as IconData),
                      size: 12,
                      color: isDone ? Colors.white : Colors.grey,
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 2,
                      height: 40,
                      color: isDone
                          ? const Color(0xFF114F3B)
                          : Colors.grey.shade200,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 28),
                child: Text(
                  steps[i]['label'] as String,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w400,
                    color: isDone ? Colors.black : Colors.grey,
                    fontSize: isCurrent ? 15 : 13,
                  ),
                ),
              ),
            ),
            // Timestamp placeholder
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                isDone ? _getTimeForStep(i) : '—',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getTimeForStep(int step) {
    // We use relative time hints since we don't have per-step timestamps
    if (step == 0) return 'Done';
    if (step == 1) return 'Done';
    return 'Done';
  }

  Widget _buildAddressCard() {
    final addr = widget.deliveryAddress;
    final String displayAddr = addr != null
        ? (addr['fullAddress'] ??
                addr['address'] ??
                addr['street'] ??
                'Your delivery address')
            .toString()
        : 'Your delivery address';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEBFFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on,
                color: Color(0xFF114F3B), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Address',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(displayAddr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard() {
    final hasRider = _riderName.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF114F3B),
            child: (hasRider && _riderName.trim().isNotEmpty)
                ? Text(
                    _riderName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : const Icon(Icons.delivery_dining,
                    color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRider ? _riderName : 'Assigning Rider...',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      hasRider ? 'Your Delivery Partner' : 'Please wait',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_riderPhone.isNotEmpty)
            _IconBtn(
              icon: Icons.call,
              isPrimary: true,
              onPressed: () => HapticFeedback.lightImpact(),
            ),
          const SizedBox(width: 10),
          _IconBtn(
            icon: Icons.chat_bubble_outline,
            isPrimary: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _getStatusSubtitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your order has been received';
      case 'accepted':
        return 'Rider is heading to pick up your order';
      case 'pickedup':
      case 'picked_up':
      case 'out_for_delivery':
      case 'out for delivery':
      case 'ontheway':
        return 'Your order is on the way! 🛵';
      case 'delivered':
        return 'Enjoy your meal! 🦐';
      default:
        return 'Tracking your order...';
    }
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _IconBtn(
      {required this.icon, required this.isPrimary, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF114F3B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isPrimary ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Icon(icon,
            color: isPrimary ? Colors.white : Colors.black87, size: 18),
      ),
    );
  }
}
