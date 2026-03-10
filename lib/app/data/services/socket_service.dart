import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Singleton Socket.IO wrapper — connects once per session.
/// Uses the auth token in headers so the server can authenticate the client.
class SocketService {
  static const String _orderUpdateEvent = 'orderUpdate';
  static const String _riderAssignedEvent = 'riderAssigned';
  static const String _newOrderEvent = 'newOrderAssigned'; // rider receives new order

  io.Socket? _socket;
  bool _initialized = false;

  // ── Connection ─────────────────────────────────────────────────────────────

  Future<void> connect(SecureStorageService storage) async {
    if (_initialized && (_socket?.connected ?? false)) return;

    final token = await storage.getAccessToken();
    final baseUrl = dotenv.maybeGet('SOCKET_URL') ??
        'https://shrimpbite-socket-server.onrender.com';

    _socket?.disconnect();

    final Map<String, dynamic> headers = token != null
        ? {'Authorization': 'Bearer $token'}
        : {};

    _socket = io.io(
      baseUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'extraHeaders': headers,
      },
    );

    _socket!.onConnect((_) => debugPrint('✅ SocketService connected'));
    _socket!.onDisconnect((_) => debugPrint('🔌 SocketService disconnected'));
    _socket!.onConnectError((err) => debugPrint('⚠️ SocketService connect error: $err'));
    _socket!.onError((err) => debugPrint('💥 SocketService error: $err'));

    _socket!.connect();
    _initialized = true;
  }

  void disconnect() {
    _socket?.disconnect();
    _initialized = false;
  }

  bool get isConnected => _socket?.connected ?? false;

  // ── Room Management ───────────────────────────────────────────────────────

  /// JOIN user room — call immediately after login for all-orders updates.
  /// `socket.emit("join", "user_{userId}")`
  void joinUserRoom(String userId) {
    _emit('join', 'user_$userId');
    debugPrint('👤 Joined user room: user_$userId');
  }

  /// JOIN rider room — rider receives new order assignments here.
  /// `socket.emit("join", "rider_{riderId}")`
  void joinRiderRoom(String riderId) {
    _emit('join', 'rider_$riderId');
    debugPrint('🛵 Joined rider room: rider_$riderId');
  }

  /// JOIN specific order room — for real-time status during tracking.
  /// `socket.emit("join", "order_{orderId}")`
  void joinOrderRoom(String orderId) {
    _emit('join', 'order_$orderId');
    debugPrint('📦 Joined order room: order_$orderId');
  }

  void leaveOrderRoom(String orderId) {
    _emit('leave', 'order_$orderId');
  }

  // ── Rider location broadcasting ──────────────────────────────────────────

  /// Rider emits their GPS coordinates during active delivery.
  void emitRiderLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) {
    _emit('riderLocation', {'orderId': orderId, 'lat': lat, 'lng': lng});
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  /// `orderUpdate` — fires on every status change.
  /// Payload: `{ status: "Out for Delivery", orderId: "ORD-...", data: {...} }`
  void onOrderUpdate(void Function(dynamic) callback) {
    _socket?.on(_orderUpdateEvent, callback);
  }

  void offOrderUpdate() => _socket?.off(_orderUpdateEvent);

  /// `riderAssigned` — fires when a rider is assigned to a user's order.
  /// Payload: `{ riderId, riderName, riderPhone, orderId }`
  void onRiderAssigned(void Function(dynamic) callback) {
    _socket?.on(_riderAssignedEvent, callback);
  }

  void offRiderAssigned() => _socket?.off(_riderAssignedEvent);

  /// `newOrderAssigned` — fires on the RIDER side when a new order is dispatched.
  /// Payload: `{ orderId, customerName, deliveryAddress, ... }`
  void onNewOrderAssigned(void Function(dynamic) callback) {
    _socket?.on(_newOrderEvent, callback);
  }

  void offNewOrderAssigned() => _socket?.off(_newOrderEvent);

  /// Generic remove listener.
  void offEvent(String event) => _socket?.off(event);

  // ── Internal ──────────────────────────────────────────────────────────────

  void _emit(String event, dynamic data) {
    if (_socket == null || !isConnected) {
      debugPrint('⚠️ SocketService._emit skipped — not connected ($event)');
      return;
    }
    _socket!.emit('emit', {'event': event, 'data': data});
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  // Connect when the provider is first read
  final storage = ref.read(storageServiceProvider);
  service.connect(storage);

  ref.onDispose(service.dispose);
  return service;
});
