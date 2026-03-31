import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as native_geo;

class GeocodingService {
  final Dio _dio = Dio();

  /// Converts lat/lng coordinates to a human-readable address with structured fields
  /// Uses Google Reverse Geocoding API for high accuracy using the MAPS_API_KEY
  /// Fails over to native Android/iOS geocoder if GCP API Key is not configured yet.
  Future<Map<String, String>?> getAddressFromLatLng(
      double latitude, double longitude) async {
    try {
      final apiKey = dotenv.get('MAPS_API_KEY');
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

      final response = await _dio.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final List results = response.data['results'];
        if (results.isNotEmpty) {
          final mostPrecise = results[0];
          final String formattedAddress = mostPrecise['formatted_address'] ?? '';
          final List components = mostPrecise['address_components'];

          String? city, state, postalCode, country;

          for (var comp in components) {
            final List types = comp['types'];
            if (types.contains('locality')) {
              city = comp['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              state = comp['long_name'];
            } else if (types.contains('postal_code')) {
              postalCode = comp['long_name'];
            } else if (types.contains('country')) {
              country = comp['long_name'];
            }
          }

          return {
            'addressLine': formattedAddress,
            'city': city ?? '',
            'state': state ?? '',
            'postalCode': postalCode ?? '',
            'country': country ?? '',
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
          };
        }
      } else {
        // ignore: avoid_print
        print('Geocoding API failed: ${response.data['status']} - ${response.data['error_message']}');
        return await _fallbackNativeGeocoding(latitude, longitude);
      }
      return await _fallbackNativeGeocoding(latitude, longitude);
    } catch (e) {
      // ignore: avoid_print
      print('Geocoding Exception (falling back): $e');
      return await _fallbackNativeGeocoding(latitude, longitude);
    }
  }

  Future<Map<String, String>?> _fallbackNativeGeocoding(double lat, double lng) async {
    try {
      List<native_geo.Placemark> placemarks = await native_geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        native_geo.Placemark place = placemarks[0];
        String addressLine = '${place.street ?? ''} ${place.subLocality ?? ''}'.trim();
        if (addressLine.isEmpty) addressLine = place.name ?? 'Unknown Location';
        
        return {
          'addressLine': addressLine,
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'state': place.administrativeArea ?? '',
          'postalCode': place.postalCode ?? '',
          'country': place.country ?? '',
          'latitude': lat.toString(),
          'longitude': lng.toString(),
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
