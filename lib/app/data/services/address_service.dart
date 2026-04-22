import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class AddressService {
  final ApiClient _client;

  AddressService(this._client);

  Future<Map<String, dynamic>> saveAddress({
    required String label,
    required String fullAddress,
    required String city,
    required String state,
    required String pincode,
    required bool isDefault,
  }) async {
    return await _client.post(
      '${ApiClient.baseUrl}/address',
      data: {
        "label": label,
        "fullAddress": fullAddress,
        "city": city,
        "state": state,
        "pincode": pincode,
        "isDefault": isDefault,
      },
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> getAddresses() async {
    return await _client.get(
      '${ApiClient.baseUrl}/address',
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> deleteAddress(String id) async {
    return await _client.delete(
      '${ApiClient.baseUrl}/address/$id',
      requiresAuth: true,
    );
  }
  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      // The backend does not appear to have a PUT /address/:id endpoint (returns 404).
      // We simulate an update by deleting the old address and saving the new one.
      await deleteAddress(id);
      return await _client.post(
        '${ApiClient.baseUrl}/address',
        data: data,
        requiresAuth: true,
      );
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService(ref.watch(apiClientProvider));
});
