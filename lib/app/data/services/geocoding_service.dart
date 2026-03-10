import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Converts lat/lng coordinates to a human-readable address with structured fields
  Future<Map<String, String>?> getAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Format to readable components
        String addressLine =
            '${place.street ?? ''} ${place.subLocality ?? ''}'.trim();
        if (addressLine.isEmpty) {
          addressLine = place.name ?? 'Unknown Location';
        }

        return {
          'addressLine': addressLine,
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'state': place.administrativeArea ?? '',
          'postalCode': place.postalCode ?? '',
          'country': place.country ?? '',
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});
