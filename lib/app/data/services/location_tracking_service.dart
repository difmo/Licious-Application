import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'rider_service.dart';
import '../network/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  RiderService? _riderService;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    // Since this runs in a separate entry-point isolate, we must ensure dotenv is loaded
    // to allow ApiClient to read the BASE_URL.
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }
    final apiClient = ApiClient();
    _riderService = RiderService(apiClient);
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    try {
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      if (_riderService != null) {
        await _riderService!
            .updateLocation(lat: position.latitude, lng: position.longitude);
      }

      FlutterForegroundTask.updateService(
        notificationTitle: 'Rider Online',
        notificationText:
            'Tracking location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      debugPrint('Error in location sync: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

class LocationTrackingService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rider_tracking',
        channelName: 'Rider Tracking',
        channelDescription: 'Maintains rider location sync in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000), // 10 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Rider Online',
      notificationText: 'Location tracking active',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
