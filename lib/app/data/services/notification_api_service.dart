import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../models/notification_model.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(apiClientProvider));
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        NotificationsNotifier.new);

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final service = ref.watch(notificationApiServiceProvider);
    return service.getNotifications();
  }

  Future<void> addNotification(NotificationModel notification) async {
    final currentData = state.asData?.value ?? [];
    state = AsyncValue.data([notification, ...currentData].take(20).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(notificationApiServiceProvider).getNotifications());
  }

  Future<void> markAsRead(String id) async {
    final success =
        await ref.read(notificationApiServiceProvider).markAsRead(id);
    if (success) {
      final currentData = state.asData?.value ?? [];
      state = AsyncValue.data(currentData.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList());
    }
  }

  Future<void> markAllAsRead() async {
    final success =
        await ref.read(notificationApiServiceProvider).markAllAsRead();
    if (success) {
      final currentData = state.asData?.value ?? [];
      state = AsyncValue.data(
          currentData.map((n) => n.copyWith(isRead: true)).toList());
    }
  }

  Future<void> deleteNotification(String id) async {
    final success =
        await ref.read(notificationApiServiceProvider).deleteNotification(id);
    if (success) {
      final currentData = state.asData?.value ?? [];
      state = AsyncValue.data(currentData.where((n) => n.id != id).toList());
    }
  }

  Future<void> deleteAllNotifications() async {
    final success =
        await ref.read(notificationApiServiceProvider).deleteAllNotifications();
    if (success) {
      state = const AsyncValue.data([]);
    }
  }
}

class NotificationApiService {
  final ApiClient _client;

  NotificationApiService(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client
          .get(
            '${ApiClient.baseUrl}/notifications',
            requiresAuth: true,
          )
          .timeout(const Duration(seconds: 10));

      final data = (response['notifications'] ?? response['data'] ?? response)
              as List? ??
          [];

      if (data.isEmpty) return _getMockNotifications();

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      // If API fails, fallback to mock data
      return _getMockNotifications();
    }
  }

  List<NotificationModel> _getMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'mock1',
        title: 'Order Delivered 🎉',
        body:
            'Your order #ORD-4589 has been delivered successfully. Enjoy your meal!',
        type: 'order',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      NotificationModel(
        id: 'mock2',
        title: 'Delivery Partner Assigned 🛵',
        body:
            'Rahul has been assigned to your order and is heading to the store.',
        type: 'delivery',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _client.patch(
        '${ApiClient.baseUrl}/notifications/read/$id',
        requiresAuth: true,
      );
      return response['success'] ?? true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _client.patch(
        '${ApiClient.baseUrl}/notifications/read-all',
        requiresAuth: true,
      );
      return response['success'] ?? true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _client.delete(
        '${ApiClient.baseUrl}/notifications/delete/$id',
        requiresAuth: true,
      );
      return response['success'] ?? true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    try {
      final response = await _client.delete(
        '${ApiClient.baseUrl}/notifications/delete-all',
        requiresAuth: true,
      );
      return response['success'] ?? true;
    } catch (e) {
      return false;
    }
  }
}
