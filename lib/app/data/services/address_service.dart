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
}
