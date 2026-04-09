import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request location permission and return the current position
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('GPS_DISABLED');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('PERMISSION_DENIED');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('PERMISSION_PERMANENTLY_DENIED');
    }

    // Attempt to get last known position first (much faster)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // If last known is less than 1 minute old, we can return it immediately
        // Otherwise we still return it but trigger a fresh fetch in the background
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 1) {
          return lastKnown;
        }
      }
    } catch (e) {
      // Ignore errors fetching last known
    }

    // When we reach here, permissions are granted and we can continue accessing the position.
    // Using LocationSettings for better platform-specific control
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // If fresh fetch fails (e.g. timeout), try to fallback to last known one last time
      final fallback = await Geolocator.getLastKnownPosition();
      if (fallback != null) return fallback;
      
      if (e is TimeoutException) {
        return Future.error('LOCATION_TIMEOUT');
      }
      return Future.error('FETCH_ERROR: $e');
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
