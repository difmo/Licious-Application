import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/api_client.dart';
import '../../../data/services/address_service.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService(ref.watch(apiClientProvider));
});
