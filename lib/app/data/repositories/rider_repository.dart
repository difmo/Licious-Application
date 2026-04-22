import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rider_model.dart';
import '../network/api_client.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/logger.dart';

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(ref.watch(apiClientProvider));
});

class RiderRepository {
  final ApiClient _client;

  RiderRepository(this._client);

  Future<RiderModel> fetchRiderProfile(String id) async {
    try {
      final json = await _client.get(
        '${ApiClient.riderBaseUrl}/profile/$id',
        requiresAuth: true,
      );
      return RiderModel.fromJson(json);
    } on ApiException catch (e) {
      AppLogger.e('RiderRepository.fetchRiderProfile: ${e.message}', e);
      throw Failure(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.e('RiderRepository.fetchRiderProfile: Unexpected error', e, stack);
      throw Failure(e.toString());
    }
  }
}
