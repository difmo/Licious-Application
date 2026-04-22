import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common_button.dart';

class LocationPermissionPage extends ConsumerStatefulWidget {
  const LocationPermissionPage({super.key});

  @override
  ConsumerState<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends ConsumerState<LocationPermissionPage> {
  bool _isRequesting = false;

  Future<void> _handlePermissionRequest() async {
    setState(() => _isRequesting = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Mark as shown so we don't show this splash again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_onboarding_shown', true);

      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        // SUCCESS: Move to Home (or auto-detect map if you prefer)
        _navigateToHome();
      } else if (permission == LocationPermission.deniedForever) {
        // PERMANENTLY DENIED: Show settings instructions
        if (mounted) {
           _showPermanentlyDeniedDialog();
        }
      } else {
        // DENIED: Just go home, we don't force it
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error requesting location: $e');
      _navigateToHome();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NOT NOW'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    ).then((_) => _navigateToHome());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Beautiful Illustration/Icon
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 80,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Enable Location',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'We use your location to show you the closest stores and deliver your fresh seafood faster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Feature list
              _benefitItem(Icons.storefront_outlined, 'Find nearby stores instantly'),
              const SizedBox(height: 16),
              _benefitItem(Icons.local_shipping_outlined, 'Ensure accurate delivery address'),
              const SizedBox(height: 16),
              _benefitItem(Icons.flash_on_outlined, 'Faster checkout experience'),
              
              const Spacer(),
              
              CommonButton(
                text: 'ALLOW LOCATION',
                isLoading: _isRequesting,
                onPressed: _handlePermissionRequest,
                backgroundColor: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                   final prefs = await SharedPreferences.getInstance();
                   await prefs.setBool('location_onboarding_shown', true);
                   _navigateToHome();
                },
                child: Text(
                  'NOT NOW, ENTER MANUALLY',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
