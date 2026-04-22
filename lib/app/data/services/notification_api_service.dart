import 'package:flutter/foundation.dart';
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
    // We update the state immediately to ensure it's reactive
    final currentData = state.asData?.value ?? [];
    // Check if duplicate ID exists to avoid double entry
    if (currentData.any((n) => n.id == notification.id)) return;
    
    state = AsyncValue.data([notification, ...currentData].take(20).toList());
  }

  Future<void> refresh() async {
    final service = ref.read(notificationApiServiceProvider);
    final newData = await service.getNotifications();
    final currentData = state.asData?.value ?? [];
    
    // Merge: unique by ID, prioritize newData but keep fcm-* ones that might not be in DB yet
    final Map<String, NotificationModel> map = {};
    for (var n in currentData) {
      map[n.id] = n;
    }
    for (var n in newData) {
      map[n.id] = n;
    }
    
    final merged = map.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    state = AsyncValue.data(merged.take(20).toList());
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

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // On real error, we can either return empty or some helpful mock
      return [];
    }
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
